# ============================================================================
# DensityPath Elastic Embedding (EE) for Seurat
# 完全版実装 - MATLABアルゴリズムと完全互換
# ============================================================================

# 必要なライブラリ
library(Seurat)
library(Matrix)

# ============================================================================
# 1. 平方距離計算（MATLABのsqdist.mと完全互換）
# ============================================================================
sqdist <- function(X, Y = NULL, w = NULL) {
  # 引数が1つの場合の高速版（最も一般的なケース）
  if (is.null(Y) && is.null(w)) {
    x <- rowSums(X^2)
    # MATLABのbsxfun(@plus,x,bsxfun(@plus,x',-2*X*X'))と同等
    sqd <- outer(x, x, "+") - 2 * (X %*% t(X))
    sqd <- pmax(sqd, 0)  # 負の値を0にクリップ（数値誤差対策）
    return(sqd)
  }
  
  # Yのデフォルト処理
  if (is.null(Y) || length(Y) == 0) {
    Y <- X
    eqXY <- TRUE
  } else {
    eqXY <- FALSE
  }
  
  # 重み付き距離の場合
  if (!is.null(w) && length(w) > 0) {
    h <- sqrt(as.vector(w))  # MATLABのw(:)'と同等
    # MATLABのbsxfun(@times,X,h)と同等
    X <- sweep(X, 2, h, "*")
    if (eqXY) {
      Y <- X
    } else {
      Y <- sweep(Y, 2, h, "*")
    }
  }
  
  # 平方距離の計算: (x-y)² = x²+y²-2xy
  x <- rowSums(X^2)
  if (eqXY) {
    y <- x  # 転置は後でouterで処理
  } else {
    y <- rowSums(Y^2)
  }
  
  # MATLABのbsxfun(@plus,x,bsxfun(@plus,y,-2*X*Y'))と同等
  sqd <- outer(x, y, "+") - 2 * (X %*% t(Y))
  sqd <- pmax(sqd, 0)  # 数値誤差対策
  
  return(sqd)
}

# ============================================================================
# 2. k近傍平方距離計算
# ============================================================================
nnsqdist <- function(X, k, method = "sort") {
  N <- nrow(X)
  k <- min(N - 1, k)
  
  # FNNパッケージが利用可能な場合は高速版を使用
  if (requireNamespace("FNN", quietly = TRUE)) {
    knn_result <- FNN::get.knn(X, k = k, algorithm = "kd_tree")
    return(list(D2 = knn_result$nn.dist^2, nn = knn_result$nn.index))
  }
  
  # 基本実装（FNNがない場合）
  D2 <- matrix(0, N, k)
  nn <- matrix(0, N, k)
  
  # 全ペアワイズ距離を計算
  D_full <- as.matrix(dist(X, method = "euclidean"))^2
  
  # 各点のk近傍を見つける
  for (i in 1:N) {
    # 自分自身を除外
    d <- D_full[i, -i]
    idx <- (1:N)[-i]
    
    # k最小値を見つける
    ord <- order(d)[1:k]
    D2[i, ] <- d[ord]
    nn[i, ] <- idx[ord]
  }
  
  return(list(D2 = D2, nn = nn))
}

# ============================================================================
# 3. betaの境界計算
# ============================================================================
eabounds <- function(logK, D2) {
  # In:
  #   logK: スカラー、perplexityの対数
  #   D2: N x k 行列、k近傍への平方距離（ソート済み）
  # Out:
  #   B: Nx2 行列、各データ点のlog-beta境界
  #   D2: 入力と同じ（微小な摂動を加える場合がある）
  
  N <- ncol(D2)  # 近傍数
  logN <- log(N)
  logNK <- logN - logK
  
  delta2 <- D2[, 2] - D2[, 1]
  
  # delta2 >= eps を保証
  ind <- which(delta2 < .Machine$double.eps)
  i <- 3
  flag <- TRUE
  
  while (length(ind) > 0 && i <= ncol(D2)) {
    if (i > exp(logK) && flag) {
      # K個以上の最近傍が同じ距離にある点の距離を微調整
      D2[ind, 1] <- D2[ind, 1] * 0.99
      flag <- FALSE
    }
    delta2[ind] <- D2[ind, i] - D2[ind, 1]
    ind <- which(delta2 < .Machine$double.eps)
    i <- i + 1
  }
  
  deltaN <- D2[, N] - D2[, 1]
  
  # p1(N, logK)を計算
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
# 4. 単一点のbetaとaffinitiesを計算
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
    
    # 関数値の計算
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
    
    # 境界の更新
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
      
      # 勾配の計算
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
# 5. Entropic Affinities (EA)メイン関数
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
  
  # 境界の計算
  bounds <- eabounds(logK, D2)
  B <- bounds$B
  D2 <- bounds$D2
  
  # 点の順序（K番目の近傍への距離でソート）
  p <- order(D2[, ceiling(K)])
  j <- p[1]
  b0 <- mean(B[j, ])
  p <- c(p, 0)
  
  # 各点のlog-betaとEAを計算
  for (i in 1:N) {
    result <- eabeta(D2[j, ], b0, logK, B[j, ])
    b[j] <- result$b
    Wp[j, ] <- result$W
    b0 <- b[j]
    j <- p[i + 1]
    if (j == 0) break
  }
  
  # スパース行列の作成
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
# 6. EEエラー関数
# ============================================================================
ee_error <- function(X, Wp, Wn, l) {
  sqd <- sqdist(X)
  ker <- exp(-sqd)
  e <- sum(Wp * sqd) + l * sum(Wn * ker)
  return(list(e = e, ker = ker))
}

# ============================================================================
# 7. バックトラッキングラインサーチ
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
# 8. Elastic Embedding (EE)メイン関数
# ============================================================================
ee <- function(Wp, Wn, d, l, opts = list()) {
  N <- nrow(Wp)
  
  # デフォルトオプション（DensityPath仕様）
  if (is.null(opts$X0)) opts$X0 <- matrix(rnorm(N * d) * 1e-5, N, d)
  if (is.null(opts$pattern)) opts$pattern <- NULL
  if (is.null(opts$tol)) opts$tol <- 1e-3
  if (is.null(opts$maxit)) opts$maxit <- Inf      # DensityPath: 制限なし
  if (is.null(opts$runtime)) opts$runtime <- Inf   # DensityPath: 制限なし
  
  start_time <- Sys.time()
  
  # 対称化とゼロ対角（既に正規化済みの前提）
  Wp <- (Wp + t(Wp)) / 2
  diag(Wp) <- 0
  Wn <- (Wn + t(Wn)) / 2
  diag(Wn) <- 0
  
  # グラフラプラシアン
  Dp <- diag(rowSums(Wp))
  Lp4 <- 4 * (Dp - Wp)
  
  # 最小の非ゼロ対角要素
  diag_Lp4 <- diag(Lp4)
  mDiagLp <- min(diag_Lp4[diag_Lp4 > 0])
  
  # Cholesky分解
  if (!is.null(opts$pattern)) {
    L_reg <- opts$pattern * Lp4 + 1e-10 * mDiagLp * diag(N)
  } else {
    L_reg <- Lp4 + 1e-10 * mDiagLp * diag(N)
  }
  
  R <- chol(L_reg)
  
  # 結果の保存用
  X_list <- list()
  E_list <- list()
  A_list <- list()
  T_list <- list()
  
  Xold <- opts$X0
  
  # 各lambda値に対して最適化（DensityPathでは単一値）
  for (i in seq_along(l)) {
    result <- ee_error(Xold, Wp, Wn, l[i])
    e <- result$e
    ker <- result$ker
    
    e_vec <- e
    a_vec <- 1
    t_vec <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    
    j <- 1
    # DensityPath用の収束条件
    convcrit <- (j < opts$maxit) && (t_vec[1] < opts$runtime)
    
    # 収束情報を出力（デバッグ用）
    if (length(l) == 1 && opts$maxit == Inf) {
      cat(sprintf("Starting optimization with lambda = %g\n", l[i]))
    }
    
    while (convcrit) {
      # 勾配計算
      WWn <- l[i] * Wn * ker
      DDn <- diag(rowSums(WWn))
      G <- (Lp4 - 4 * (DDn - WWn)) %*% Xold
      
      # Spectral direction
      P <- -backsolve(R, backsolve(t(R), G))
      
      # ラインサーチ
      ls_result <- eels(Xold, Wp, Wn, l[i], P, e_vec[j], G, a_vec[j])
      X <- ls_result$X
      e_vec <- c(e_vec, ls_result$e)
      ker <- ls_result$ker
      a_vec <- c(a_vec, ls_result$alpha)
      
      # 収束判定（DensityPath用）
      rel_change <- norm(X - Xold, "F") / norm(Xold, "F")
      convcrit <- (j < opts$maxit) && 
                  (as.numeric(difftime(Sys.time(), start_time, units = "secs")) < opts$runtime) &&
                  (rel_change > opts$tol)
      
      # 定期的に進捗を出力（デバッグ用）
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
    
    # 結果の保存
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
# 9. メインのSeurat統合関数
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
  
  # ランダムシードの設定
  if (!is.null(seed)) {
    set.seed(seed)
    if (verbose) cat(sprintf("Random seed set to: %d\n", seed))
  }

  # reduction名の決定
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
  
  # Assayの自動検出
  if (is.null(assay)) {
    assay <- DefaultAssay(seurat_obj)
  }
  
  # データの準備
  if (!is.null(reduction)) {
    # reductionを使用
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

  # DensityPath方式の正規化
  # MATLABコード: Y = Y-min(Y(:)); Y = Y./max(Y(:));
  if (verbose) cat("Normalizing data (DensityPath style)...\n")
  X_min <- min(X)  # 全要素の最小値
  X <- X - X_min   # 最小値を0にシフト
  X_max <- max(X)  # シフト後の最大値
  X <- X / X_max   # [0,1]に正規化

  N <- nrow(X)
  if (is.null(k_neighbors)) k_neighbors <- min(3 * perplexity, N - 1)
  
  # Step 1: Gaussian Entropic Affinities (Wp)
  if (verbose) cat("Computing entropic affinities...\n")
  ea_result <- ea(X, K = perplexity, k = k_neighbors)
  Wp <- as.matrix(ea_result$W)
  
  # Step 2: 負の重み行列 (Wn) - 平方距離行列
  if (verbose) cat("Computing negative affinities from squared distances...\n")
  Wn <- sqdist(X)
  
  # Step 3: DensityPath方式の正規化
  # MATLABデモコードと同じ正規化
  if (verbose) cat("Normalizing weight matrices...\n")
  
  # Wpの正規化
  Wp <- (Wp + t(Wp)) / 2  # 対称化
  diag(Wp) <- 0           # 対角要素を0に
  Wp <- Wp / sum(Wp)      # 全体の和を1に正規化
  
  # Wnの正規化
  Wn <- (Wn + t(Wn)) / 2  # 対称化
  diag(Wn) <- 0           # 対角要素を0に
  Wn <- Wn / sum(Wn)      # 全体の和を1に正規化
  
  # Step 4: 収束条件の変更
  # DensityPathの説明: "cancel the limitation of the running time and maximum iteration"
  if (verbose) cat("Running Elastic Embedding optimization (no iteration limit)...\n")
  
  ee_result <- ee(Wp = Wp, 
                  Wn = Wn, 
                  d = d, 
                  l = lambda,  # 単一のlambda値を使用
                  opts = list(
                    X0 = matrix(rnorm(N * d) * 1e-5, N, d),  # デモと同じ初期化
                    tol = 1e-3,
                    maxit = Inf,      # 反復回数制限なし
                    runtime = Inf     # 実行時間制限なし
                  ))
  
  # 最終的な埋め込みを取得
  Y <- ee_result$X

  # 各次元を中心化
  Y <- scale(Y, center = TRUE, scale = FALSE)

  # 結果をSeuratオブジェクトに追加
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
