# ============================================================================
# DensityPath Elastic Embedding (EE) for Seurat
# Full implementation - Fully compatible with MATLAB algorithm
# ============================================================================

# Required libraries
library(Seurat)
library(Matrix)

# ============================================================================
# 1. Squared distance calculation (fully compatible with MATLAB sqdist.m)
# ============================================================================
sqdist <- function(X, Y = NULL, w = NULL) {
  # Fast version for single argument (most common case)
  if (is.null(Y) && is.null(w)) {
    x <- rowSums(X^2)
    # Equivalent to MATLAB bsxfun(@plus,x,bsxfun(@plus,x',-2*X*X'))
    sqd <- outer(x, x, "+") - 2 * (X %*% t(X))
    sqd <- pmax(sqd, 0)  # Clip negative values to 0 (numerical error handling)
    return(sqd)
  }
  
  # Default handling of Y
  if (is.null(Y) || length(Y) == 0) {
    Y <- X
    eqXY <- TRUE
  } else {
    eqXY <- FALSE
  }
  
  # For weighted distances
  if (!is.null(w) && length(w) > 0) {
    h <- sqrt(as.vector(w))  # Equivalent to MATLAB w(:)'
    # Equivalent to MATLAB bsxfun(@times,X,h)
    X <- sweep(X, 2, h, "*")
    if (eqXY) {
      Y <- X
    } else {
      Y <- sweep(Y, 2, h, "*")
    }
  }
  
  # Squared distance calculation: (x-y)² = x²+y²-2xy
  x <- rowSums(X^2)
  if (eqXY) {
    y <- x  # Transpose handled later with outer
  } else {
    y <- rowSums(Y^2)
  }
  
  # Equivalent to MATLAB bsxfun(@plus,x,bsxfun(@plus,y,-2*X*Y'))
  sqd <- outer(x, y, "+") - 2 * (X %*% t(Y))
  sqd <- pmax(sqd, 0)  # Numerical error handling
  
  return(sqd)
}

# ============================================================================
# 2. k-nearest neighbor squared distance calculation
# ============================================================================
nnsqdist <- function(X, k, method = "sort") {
  N <- nrow(X)
  k <- min(N - 1, k)
  
  # Use fast version if FNN package is available
  if (requireNamespace("FNN", quietly = TRUE)) {
    knn_result <- FNN::get.knn(X, k = k, algorithm = "kd_tree")
    return(list(D2 = knn_result$nn.dist^2, nn = knn_result$nn.index))
  }
  
  # Basic implementation (if FNN not available)
  D2 <- matrix(0, N, k)
  nn <- matrix(0, N, k)
  
  # Calculate all pairwise distances
  D_full <- as.matrix(dist(X, method = "euclidean"))^2
  
  # Find k neighbors for each point
  for (i in 1:N) {
    # Exclude self
    d <- D_full[i, -i]
    idx <- (1:N)[-i]
    
    # Find k minimum values
    ord <- order(d)[1:k]
    D2[i, ] <- d[ord]
    nn[i, ] <- idx[ord]
  }
  
  return(list(D2 = D2, nn = nn))
}

# ============================================================================
# 3. Beta boundary calculation
# ============================================================================
eabounds <- function(logK, D2) {
  # In:
  #   logK: Scalar, log of perplexity
  #   D2: N x k matrix, squared distances to k neighbors (sorted)
  # Out:
  #   B: Nx2 matrix, log-beta boundaries for each data point
  #   D2: Same as input (may add small perturbations)
  
  N <- ncol(D2)  # Number of neighbors
  logN <- log(N)
  logNK <- logN - logK
  
  delta2 <- D2[, 2] - D2[, 1]
  
  # Ensure delta2 >= eps
  ind <- which(delta2 < .Machine$double.eps)
  i <- 3
  flag <- TRUE
  
  while (length(ind) > 0 && i <= ncol(D2)) {
    if (i > exp(logK) && flag) {
      # Fine-tune distances for points with K or more equal-distance neighbors
      D2[ind, 1] <- D2[ind, 1] * 0.99
      flag <- FALSE
    }
    delta2[ind] <- D2[ind, i] - D2[ind, 1]
    ind <- which(delta2 < .Machine$double.eps)
    i <- i + 1
  }
  
  deltaN <- D2[, N] - D2[, 1]
  
  # Calculate p1(N, logK)
  if (logK > log(sqrt(2 * N))) {
    p1 <- 3/4
  } else {
    p1 <- 1/4
    for (i in 1:100) {
      e <- -p1 * log(p1/N) - logK
      g <- -log(p1/N) + 1
      p1 <- p1 - e/g
    }
    p1 <- 1 - p1/2
  }
  
  bU1 <- (2 * log(p1 * (N - 1) / (1 - p1))) / delta2
  bL1 <- (2 * logNK / (1 - 1/N)) / deltaN
  bL2 <- (2 * sqrt(logNK)) / sqrt(D2[, N]^2 - D2[, 1]^2)
  
  B <- cbind(log(pmax(bL1, bL2)), log(bU1))
  
  return(list(B = B, D2 = D2))
}

# ============================================================================
# 4. Calculate beta and affinities for a single point
# ============================================================================
eabeta <- function(d2, b0, logK, B, maxit = 20, tol = 1e-10) {
  if (b0 < B[1] || b0 > B[2]) {
    b <- (B[1] + B[2]) / 2
  } else {
    b <- b0
  }
  
  i <- 1
  
  while (TRUE) {
    bE <- exp(b)
    pbm <- FALSE
    
    # Calculate function value
    ed2 <- exp(-d2 * bE)
    m0 <- sum(ed2)
    
    if (m0 < .Machine$double.xmin) {
      e <- -logK
      pbm <- TRUE
    } else {
      m1v <- ed2 * d2 / m0
      m1 <- sum(m1v)
      e <- bE * m1 + log(m0) - logK
    }
    
    if (abs(e) < tol) break
    
    if (B[2] - B[1] < 10 * .Machine$double.eps) break
    
    # Update boundaries
    if (e < 0 && b <= B[2]) {
      B[2] <- b
    } else if (e > 0 && b >= B[1]) {
      B[1] <- b
    }
    
    pbm <- pbm || is.infinite(e) || e < -logK || e > log(length(d2)) - logK
    
    if (!pbm) {
      if (i == maxit) {
        b <- (B[1] + B[2]) / 2
        i <- 1
        next
      }
      
      # Calculate gradient
      eg2 <- bE^2
      m2 <- sum(m1v * d2)
      m12 <- m1^2 - m2
      g <- eg2 * m12
      
      if (g == 0) pbm <- TRUE
    }
    
    if (pbm) {
      esqd1 <- exp(-d2 * exp(B[1]))
      esqd2 <- exp(-d2 * exp(B[2]))
      if (sum(esqd1 + esqd2) < 2 * sqrt(.Machine$double.xmin)) break
      b <- (B[1] + B[2]) / 2
      i <- 1
      next
    }
    
    # Newton step
    p <- -e / g
    b <- b + p
    
    if (b < B[1] || b > B[2]) {
      b <- (B[1] + B[2]) / 2
      i <- 0
    }
    
    i <- i + 1
  }
  
  W <- ed2 / m0
  
  return(list(b = b, W = W))
}

# ============================================================================
# 5. Entropic Affinities (EA) main function
# ============================================================================
ea <- function(X, K, k = NULL) {
  N <- nrow(X)
  
  if (is.null(k)) k <- N - 1
  
  if (is.list(k)) {
    D2 <- k$D2
    nn <- k$nn
    k <- ncol(D2)
  } else {
    nns <- nnsqdist(X, k)
    D2 <- nns$D2
    nn <- nns$nn
  }
  
  b <- numeric(N)
  Wp <- matrix(0, N, k)
  logK <- log(K)
  
  # Calculate boundaries
  bounds <- eabounds(logK, D2)
  B <- bounds$B
  D2 <- bounds$D2
  
  # Point ordering (sort by distance to K-th neighbor)
  p <- order(D2[, ceiling(K)])
  j <- p[1]
  b0 <- mean(B[j, ])
  p <- c(p, 0)
  
  # Calculate log-beta and EA for each point
  for (i in 1:N) {
    result <- eabeta(D2[j, ], b0, logK, B[j, ])
    b[j] <- result$b
    Wp[j, ] <- result$W
    b0 <- b[j]
    j <- p[i + 1]
    if (j == 0) break
  }
  
  # Create sparse matrix
  if (k >= N - 1) {
    W <- matrix(0, N, N)
    for (i in 1:N) {
      W[i, nn[i, ]] <- Wp[i, ]
    }
  } else {
    i_indices <- rep(1:N, each = k)
    j_indices <- as.vector(t(nn))
    W <- sparseMatrix(i = i_indices, j = j_indices, x = as.vector(t(Wp)), dims = c(N, N))
  }
  
  s <- 1 / sqrt(2 * exp(b))
  
  return(list(W = W, s = s))
}

# ============================================================================
# 6. EE error function
# ============================================================================
ee_error <- function(X, Wp, Wn, l) {
  sqd <- sqdist(X)
  ker <- exp(-sqd)
  e <- sum(Wp * sqd) + l * sum(Wn * ker)
  return(list(e = e, ker = ker))
}

# ============================================================================
# 7. Backtracking line search
# ============================================================================
eels <- function(X, Wp, Wn, l, P, ff, G, alpha0 = 1, rho = 0.8, c = 1e-1) {
  alpha <- alpha0
  tmp <- c * sum(G * P)
  
  result <- ee_error(X + alpha * P, Wp, Wn, l)
  e <- result$e
  ker <- result$ker
  
  while (e > ff + alpha * tmp) {
    alpha <- rho * alpha
    result <- ee_error(X + alpha * P, Wp, Wn, l)
    e <- result$e
    ker <- result$ker
  }
  
  X <- X + alpha * P
  
  return(list(X = X, e = e, ker = ker, alpha = alpha))
}

# ============================================================================
# 8. Elastic Embedding (EE) main function
# ============================================================================
ee <- function(Wp, Wn, d, l, opts = list()) {
  N <- nrow(Wp)
  
  # Default options (DensityPath specification)
  if (is.null(opts$X0)) opts$X0 <- matrix(rnorm(N * d) * 1e-5, N, d)
  if (is.null(opts$pattern)) opts$pattern <- NULL
  if (is.null(opts$tol)) opts$tol <- 1e-3
  if (is.null(opts$maxit)) opts$maxit <- Inf      # DensityPath: no limit
  if (is.null(opts$runtime)) opts$runtime <- Inf   # DensityPath: no limit
  
  start_time <- Sys.time()
  
  # Symmetrize and zero diagonal (assuming already normalized)
  Wp <- (Wp + t(Wp)) / 2
  diag(Wp) <- 0
  Wn <- (Wn + t(Wn)) / 2
  diag(Wn) <- 0
  
  # Graph Laplacian
  Dp <- diag(rowSums(Wp))
  Lp4 <- 4 * (Dp - Wp)
  
  # Minimum non-zero diagonal element
  diag_Lp4 <- diag(Lp4)
  mDiagLp <- min(diag_Lp4[diag_Lp4 > 0])
  
  # Cholesky decomposition
  if (!is.null(opts$pattern)) {
    L_reg <- opts$pattern * Lp4 + 1e-10 * mDiagLp * diag(N)
  } else {
    L_reg <- Lp4 + 1e-10 * mDiagLp * diag(N)
  }
  
  R <- chol(L_reg)
  
  # For storing results
  X_list <- list()
  E_list <- list()
  A_list <- list()
  T_list <- list()
  
  Xold <- opts$X0
  
  # Optimize for each lambda value (single value for DensityPath)
  for (i in seq_along(l)) {
    result <- ee_error(Xold, Wp, Wn, l[i])
    e <- result$e
    ker <- result$ker
    
    e_vec <- e
    a_vec <- 1
    t_vec <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    
    j <- 1
    # Convergence criteria for DensityPath
    convcrit <- (j < opts$maxit) && (t_vec[1] < opts$runtime)
    
    # Output convergence information (for debugging)
    if (length(l) == 1 && opts$maxit == Inf) {
      cat(sprintf("Starting optimization with lambda = %g\n", l[i]))
    }
    
    while (convcrit) {
      # Gradient calculation
      WWn <- l[i] * Wn * ker
      DDn <- diag(rowSums(WWn))
      G <- (Lp4 - 4 * (DDn - WWn)) %*% Xold
      
      # Spectral direction
      P <- -backsolve(R, backsolve(t(R), G))
      
      # Line search
      ls_result <- eels(Xold, Wp, Wn, l[i], P, e_vec[j], G, a_vec[j])
      X <- ls_result$X
      e_vec <- c(e_vec, ls_result$e)
      ker <- ls_result$ker
      a_vec <- c(a_vec, ls_result$alpha)
      
      # Convergence test (for DensityPath)
      rel_change <- norm(X - Xold, "F") / norm(Xold, "F")
      convcrit <- (j < opts$maxit) && 
                  (as.numeric(difftime(Sys.time(), start_time, units = "secs")) < opts$runtime) &&
                  (rel_change > opts$tol)
      
      # Periodically output progress (for debugging)
      if (j %% 10 == 0 && length(l) == 1) {
        cat(sprintf("  Iteration %d: error = %g, relative change = %g\n", 
                    j, e_vec[j+1], rel_change))
      }
      
      Xold <- X
      j <- j + 1
      t_vec <- c(t_vec, as.numeric(difftime(Sys.time(), start_time, units = "secs")))
    }
    
    if (length(l) == 1) {
      cat(sprintf("Converged after %d iterations (relative change: %g)\n", 
                  j-1, rel_change))
    }
    
    # Save results
    if (length(l) == 1) {
      X_list <- X
      E_list <- e_vec
      A_list <- a_vec
      T_list <- t_vec
    } else {
      X_list[[i]] <- X
      E_list[[i]] <- e_vec
      A_list[[i]] <- a_vec
      T_list[[i]] <- t_vec
    }
  }
  
  return(list(X = X_list, E = E_list, A = A_list, T = T_list))
}

# ============================================================================
# 9. Main Seurat integration function
# ============================================================================
densitypath_ee_matlab_exact <- function(seurat_obj, 
                                       d = 2,
                                       perplexity = 30,
                                       lambda = 10,
                                       k_neighbors = NULL,
                                       reduction = "pca",
                                       n_dims = NULL,
                                       assay = NULL,
                                       seed = 42,
                                       verbose = TRUE) {
  
  # Set random seed
  if (!is.null(seed)) {
    set.seed(seed)
    if (verbose) cat(sprintf("Random seed set to: %d\n", seed))
  }

  # Determine reduction name
  if (!is.null(reduction)) {
    reduction_name <- paste(reduction, "EE", sep = ".")
    reduction_key <- paste0(reduction, "EE_")
  } else {
    reduction_name <- "EE"
    reduction_key <- "EE_"
  }
  
  if (verbose) {
    cat("=== DensityPath Elastic Embedding Parameters ===\n")
    cat(sprintf("- Input: %s\n", ifelse(!is.null(reduction), reduction, "raw data")))
    cat(sprintf("- Output: %s\n", reduction_name))
    cat(sprintf("- Lambda: %g\n", lambda))
    cat(sprintf("- Perplexity: %g\n", perplexity))
    cat("===============================================\n\n")
  }
  
  # Auto-detect Assay
  if (is.null(assay)) {
    assay <- DefaultAssay(seurat_obj)
  }
  
  # Data preparation
  if (!is.null(reduction)) {
    # Use reduction
    if (!reduction %in% names(seurat_obj@reductions)) {
      stop(sprintf("Reduction '%s' not found. Available: %s", 
                   reduction, 
                   paste(names(seurat_obj@reductions), collapse = ", ")))
    }
    
    reduction_embeddings <- seurat_obj@reductions[[reduction]]@cell.embeddings
    n_dims <- ifelse(is.null(n_dims), ncol(reduction_embeddings), 
                     min(n_dims, ncol(reduction_embeddings)))
    X <- reduction_embeddings[, 1:n_dims]
  }

  # DensityPath-style normalization
  # MATLAB code: Y = Y-min(Y(:)); Y = Y./max(Y(:));
  if (verbose) cat("Normalizing data (DensityPath style)...\n")
  X_min <- min(X)  # Minimum value of all elements
  X <- X - X_min   # Shift to make minimum 0
  X_max <- max(X)  # Maximum after shift
  X <- X / X_max   # Normalize to [0,1]

  N <- nrow(X)
  if (is.null(k_neighbors)) k_neighbors <- min(3 * perplexity, N - 1)
  
  # Step 1: Gaussian Entropic Affinities (Wp)
  if (verbose) cat("Computing entropic affinities...\n")
  ea_result <- ea(X, K = perplexity, k = k_neighbors)
  Wp <- as.matrix(ea_result$W)
  
  # Step 2: Negative weight matrix (Wn) - squared distance matrix
  if (verbose) cat("Computing negative affinities from squared distances...\n")
  Wn <- sqdist(X)
  
  # Step 3: DensityPath-style normalization
  # Same normalization as MATLAB demo code
  if (verbose) cat("Normalizing weight matrices...\n")

  # Wp normalization
  Wp <- (Wp + t(Wp)) / 2  # Symmetrize
  diag(Wp) <- 0           # Set diagonal to 0
  Wp <- Wp / sum(Wp)      # Normalize sum to 1

  # Wn normalization
  Wn <- (Wn + t(Wn)) / 2  # Symmetrize
  diag(Wn) <- 0           # Set diagonal to 0
  Wn <- Wn / sum(Wn)      # Normalize sum to 1
  
  # Step 4: Convergence condition change
  # DensityPath description: "cancel the limitation of the running time and maximum iteration"
  if (verbose) cat("Running Elastic Embedding optimization (no iteration limit)...\n")
  
  ee_result <- ee(Wp = Wp, 
                  Wn = Wn, 
                  d = d, 
                  l = lambda,  # Use single lambda value
                  opts = list(
                    X0 = matrix(rnorm(N * d) * 1e-5, N, d),  # Same initialization as demo
                    tol = 1e-3,
                    maxit = Inf,      # No iteration limit
                    runtime = Inf     # No time limit
                  ))
  
  # Get final embedding
  Y <- ee_result$X

  # Center each dimension
  Y <- scale(Y, center = TRUE, scale = FALSE)

  # Add results to Seurat object
  colnames(Y) <- paste0(reduction_key, 1:d)
  rownames(Y) <- colnames(seurat_obj)
  
  seurat_obj[[reduction_name]] <- CreateDimReducObject(
    embeddings = Y,
    key = reduction_key,
    assay = assay
  )
  
  if (verbose) {
    cat("\nDensityPath Elastic Embedding completed successfully!\n")
    cat(sprintf("Final error: %g\n", ee_result$E[length(ee_result$E)]))
    cat(sprintf("Iterations: %d\n", length(ee_result$E)))
  }
  
  return(seurat_obj)
}
