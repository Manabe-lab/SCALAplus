# BoneMarrowMap Seurat v5 compatibility patch
# This file provides modified versions of BoneMarrowMap functions
# that are compatible with Seurat v5 (using 'layer' instead of 'slot')

# Required packages
library(dplyr)
library(BiocNeighbors)

#' ProjectDim - Seurat v5 compatible version
#' Projects feature loadings onto a dimension reduction
#' Modified to use 'layer' instead of deprecated 'slot' argument
#'
ProjectDim_v5 <- function(object, reduction = "pca", assay = NULL,
                          dims.print = 1:5, nfeatures.print = 20,
                          overwrite = FALSE, do.center = FALSE, verbose = TRUE) {
  redeuc <- object[[reduction]]
  assay <- assay %||% Seurat::DefaultAssay(object = redeuc)

  # MODIFIED: Use 'layer' instead of 'slot' for Seurat v5 compatibility
  data.use <- tryCatch({
    Seurat::GetAssayData(object = object[[assay]], layer = "scale.data")
  }, error = function(e) {
    # Fallback: try to get data layer if scale.data doesn't exist
    tryCatch({
      Seurat::GetAssayData(object = object[[assay]], layer = "data")
    }, error = function(e2) {
      warning("Could not retrieve scale.data or data layer, skipping ProjectDim")
      return(NULL)
    })
  })

  if (is.null(data.use)) {
    return(object)
  }

  if (do.center) {
    data.use <- scale(x = as.matrix(x = data.use), center = TRUE, scale = FALSE)
  }

  cell.embeddings <- Seurat::Embeddings(object = redeuc)

  # Ensure matching features between data and embeddings
  common.features <- intersect(rownames(data.use), rownames(cell.embeddings))
  if (length(common.features) == 0) {
    # Project all features
    new.feature.loadings.full <- as.matrix(data.use) %*% cell.embeddings
  } else {
    new.feature.loadings.full <- as.matrix(data.use) %*% cell.embeddings
  }

  rownames(x = new.feature.loadings.full) <- rownames(x = data.use)
  colnames(x = new.feature.loadings.full) <- colnames(x = cell.embeddings)

  Seurat::Loadings(object = redeuc, projected = TRUE) <- new.feature.loadings.full
  if (overwrite) {
    Seurat::Loadings(object = redeuc, projected = FALSE) <- new.feature.loadings.full
  }

  object[[reduction]] <- redeuc

  if (verbose) {
    print(x = redeuc, dims = dims.print, nfeatures = nfeatures.print, projected = TRUE)
  }

  return(object)
}

#' Map Query - Seurat v5 compatible version
#' Modified from BoneMarrowMap::map_Query
#'
map_Query_v5 <- function (exp_query, metadata_query, ref_obj, vars = NULL, verbose = TRUE,
                          do_normalize = TRUE, do_umap = TRUE, sigma = 0.1)
{
  que <- Seurat::CreateSeuratObject(
    counts=exp_query,
    meta.data=metadata_query,
    assay='RNA'
  )

  if (do_normalize) {
    if (verbose)
      message("Normalizing")
    exp_query = symphony:::normalizeData(exp_query, 10000, "log")
  }
  if (verbose)
    message("Scaling and synchronizing query gene expression")
  idx_shared_genes = which(ref_obj$vargenes$symbol %in% rownames(exp_query))
  shared_genes = ref_obj$vargenes$symbol[idx_shared_genes]
  if (verbose)
    message("Found ", length(shared_genes), " reference variable genes in query dataset")
  exp_query_scaled = symphony::scaleDataWithStats(exp_query[shared_genes,
  ], ref_obj$vargenes$mean[idx_shared_genes], ref_obj$vargenes$stddev[idx_shared_genes],
  1)
  exp_query_scaled_sync = matrix(0, nrow = length(ref_obj$vargenes$symbol),
                                 ncol = ncol(exp_query))
  exp_query_scaled_sync[idx_shared_genes, ] = exp_query_scaled
  rownames(exp_query_scaled_sync) = ref_obj$vargenes$symbol
  colnames(exp_query_scaled_sync) = colnames(exp_query)
  if (verbose)
    message("Project query cells using reference gene loadings")
  Z_pca_query = t(ref_obj$loadings) %*% exp_query_scaled_sync
  if (verbose)
    message("Clustering query cells to reference centroids")
  Z_pca_query_cos = symphony:::cosine_normalize_cpp(Z_pca_query, 2)
  R_query = symphony:::soft_cluster(ref_obj$centroids, Z_pca_query_cos,
                                    sigma)
  if (verbose)
    message("Correcting query batch effects")
  if (!is.null(vars)) {
    if (verbose) message("  Batch variable: ", vars)
    # Ensure we get a data.frame even with single column
    design = droplevels(metadata_query)[, vars, drop = FALSE]
    if (verbose) {
      message("  Design matrix dimensions: ", nrow(design), " x ", ncol(design))
      message("  Batch levels: ", paste(unique(design[[1]]), collapse = ", "))
      message("  Batch counts: ", paste(table(design[[1]]), collapse = ", "))
    }
    onehot = design %>% purrr::map(function(.x) {
      n_unique <- length(unique(.x))
      if (n_unique == 1) {
        if (verbose) message("  WARNING: Only 1 batch level found - no batch correction possible")
        rep(1, length(.x))
      }
      else {
        if (verbose) message("  Creating one-hot encoding for ", n_unique, " batch levels")
        stats::model.matrix(~0 + .x)
      }
    }) %>% purrr::reduce(cbind)
    Xq = cbind(1, intercept = onehot) %>% t()
    if (verbose) message("  Design matrix Xq dimensions: ", nrow(Xq), " x ", ncol(Xq))
  }
  else {
    if (verbose) message("  No batch variable specified - skipping batch correction")
    Xq = Matrix::Matrix(rbind(rep(1, ncol(Z_pca_query)), rep(1, ncol(Z_pca_query))),
                        sparse = TRUE)
  }
  Zq_corr = symphony:::moe_correct_ref(as.matrix(Z_pca_query), as.matrix(Xq),
                                       as.matrix(R_query), as.matrix(ref_obj$cache[[1]]), as.matrix(ref_obj$cache[[2]]))
  colnames(Z_pca_query) = row.names(metadata_query)
  rownames(Z_pca_query) = paste0("PC_", seq_len(nrow(Zq_corr)))
  colnames(Zq_corr) = row.names(metadata_query)
  rownames(Zq_corr) = paste0("harmony_", seq_len(nrow(Zq_corr)))
  umap_query = NULL
  if (do_umap & !is.null(ref_obj$save_uwot_path)) {
    if (verbose)
      message("UMAP")
    ref_umap_model = uwot::load_uwot(ref_obj$save_uwot_path,
                                     verbose = FALSE)

    ## UMAP may have been learned on subset of columns
    umap_query = uwot::umap_transform(t(Zq_corr)[, 1:ref_umap_model$norig_col], ref_umap_model)
    colnames(umap_query) = c("UMAP1", "UMAP2")
    rownames(umap_query) <- row.names(metadata_query)
  }
  if (verbose)
    message("All done!")

  # Return Seurat Object - MODIFIED FOR SEURAT V5 COMPATIBILITY
  # Use 'layer' instead of deprecated 'slot' argument
  que <- Seurat::SetAssayData(object = que, assay = 'RNA', layer = "data", new.data = exp_query)
  que <- Seurat::SetAssayData(object = que, assay = 'RNA', layer = "scale.data", new.data = exp_query_scaled_sync)

  que[['pca_projected']] <- Seurat::CreateDimReducObject(
    embeddings = t(Z_pca_query),
    loadings = ref_obj$loadings,
    stdev = as.numeric(apply(Z_pca_query, 1, stats::sd)),
    assay = 'RNA',
    key = 'pca_'
  )
  que[['harmony_projected']] <- Seurat::CreateDimReducObject(
    embeddings = t(Zq_corr),
    stdev = as.numeric(apply(Zq_corr, 1, stats::sd)),
    assay = 'RNA',
    key = 'harmony_',
    misc=list(R=R_query)
  )
  # Use v5 compatible ProjectDim
  que <- ProjectDim_v5(que, reduction = 'harmony_projected', overwrite = TRUE, verbose = FALSE)
  if (do_umap) {
    que[['umap_projected']] <- Seurat::CreateDimReducObject(
      embeddings = umap_query,
      assay = 'RNA',
      key = 'umap_'
    )
  }
  return(que)
}

#' Calculate Mapping Error - Seurat v5 compatible version
#' Uses 'pca_projected' and 'harmony_projected' reduction names
#'
calculate_MappingError_v5 <- function(query, reference, MAD_threshold = 2.5,
                                       threshold_by_donor = FALSE, donor_key = NULL) {
  # Use _projected suffix for reduction names (created by map_Query_v5)
  query_pca <- t(query@reductions$pca_projected@cell.embeddings)
  query_R <- query@reductions$harmony_projected@misc$R

  mah_dist_ks <- matrix(rep(0, len = ncol(query_pca) * ncol(reference$centroids)),
                         nrow = ncol(query_pca))
  for (k in 1:ncol(reference$centroids)) {
    mah_dist_ks[, k] <- sqrt(stats::mahalanobis(
      x = t(query_pca),
      center = reference$center_ks[, k],
      cov = reference$cov_ks[[k]]
    ))
  }
  maha <- rowSums(mah_dist_ks * t(query_R))
  query$mapping_error_score <- maha

  if (threshold_by_donor == TRUE) {
    if (!donor_key %in% colnames(query@meta.data)) {
      stop(paste0("Label \"", donor_key, "\" is not available in the query metadata."))
    }
    query$mapping_error_QC <- query@meta.data %>%
      dplyr::group_by(get(donor_key)) %>%
      dplyr::mutate(mapping_error_QC = ifelse(
        mapping_error_score > (stats::median(mapping_error_score) + MAD_threshold * stats::mad(mapping_error_score)),
        "Fail", "Pass"
      )) %>%
      dplyr::ungroup() %>%
      dplyr::pull(mapping_error_QC)
  } else {
    query$mapping_error_QC <- ifelse(
      query$mapping_error_score < (stats::median(query$mapping_error_score) + MAD_threshold * stats::mad(query$mapping_error_score)),
      "Pass", "Fail"
    )
  }
  return(query)
}

#' kNN Predict - Seurat v5 compatible version
#' Uses 'harmony_projected' reduction name
#'
knnPredict_Seurat_v5 <- function(query_obj, ref_obj, label_transfer, col_name,
                                  k = 5, confidence = TRUE, seed = 0) {
  set.seed(seed)
  if (!label_transfer %in% colnames(ref_obj$meta_data)) {
    stop(paste0("Label \"", label_transfer, "\" is not available in the reference metadata."))
  }

  # Use harmony_projected instead of harmony
  knn_pred <- BiocNeighbors::queryKNN(
    X = t(ref_obj$Z_corr),
    query = Seurat::Embeddings(query_obj, "harmony_projected"),
    k = k
  )

  knn_pred_labels <- apply(knn_pred$index, 1, function(x) {
    label <- names(which.max(table(ref_obj$meta_data[, label_transfer][x])))
    if (length(label) > 1) {
      label <- unlist(label)[sample(1, length(label), replace = FALSE)]
    }
    label
  })

  if (confidence) {
    knn_prob <- apply(knn_pred$index, 1, function(x) {
      max(table(ref_obj$meta_data[, label_transfer][x])) / k
    })
    query_obj@meta.data[paste0(col_name, "_prob")] <- knn_prob
  }
  query_obj@meta.data[[col_name]] <- as.character(knn_pred_labels)
  return(query_obj)
}

#' Predict Cell Types - Seurat v5 compatible version
#' Uses v5 compatible kNN prediction
#'
predict_CellTypes_v5 <- function(query_obj, ref_obj, ref_label = "CellType_Annotation",
                                  k = 30, mapQC_col = "mapping_error_QC",
                                  initial_label = "initial_CellType",
                                  final_label = "predicted_CellType",
                                  include_broad = TRUE) {
  if (!ref_label %in% colnames(ref_obj$meta_data)) {
    stop(paste0("Label \"", ref_label, "\" is not available in the reference metadata."))
  }

  query_obj <- knnPredict_Seurat_v5(
    query_obj = query_obj,
    ref_obj = ref_obj,
    label_transfer = ref_label,
    col_name = initial_label,
    k = k
  )

  query_obj@meta.data[[initial_label]] <- query_obj@meta.data[[initial_label]] %>% as.character()

  if (is.null(mapQC_col) || is.na(mapQC_col)) {
    query_obj@meta.data[[final_label]] <- query_obj@meta.data[[initial_label]]
    query_obj@meta.data[[paste0(final_label, "_prob")]] <- query_obj@meta.data[[paste0(initial_label, "_prob")]]
  } else {
    query_obj@meta.data[[final_label]] <- ifelse(
      query_obj@meta.data[[mapQC_col]] %in% c("Fail", "fail"),
      NA,
      query_obj@meta.data[[initial_label]]
    )
    query_obj@meta.data[[paste0(final_label, "_prob")]] <- ifelse(
      query_obj@meta.data[[mapQC_col]] %in% c("Fail", "fail"),
      NA,
      query_obj@meta.data[[paste0(initial_label, "_prob")]]
    )
  }

  if ((ref_label == "CellType_Annotation") & (include_broad == TRUE)) {
    if (!"CellType_Broad" %in% colnames(ref_obj$meta_data)) {
      stop("Label \"CellType_Broad\" is not available in the reference metadata.")
    }
    if (!"CellType_No_Abbreviations" %in% colnames(ref_obj$meta_data)) {
      stop("Label \"CellType_No_Abbreviations\" is not available in the reference metadata.")
    }

    celltype_conversion <- unique(ref_obj$meta_data[c(ref_label, "CellType_Broad", "CellType_No_Abbreviations")])
    # Ensure vectors for match() - Seurat v5 may return non-vector types
    final_label_values <- as.character(query_obj@meta.data[[final_label]])
    celltype_annotation_values <- as.character(celltype_conversion$CellType_Annotation)

    query_obj@meta.data[[paste0(final_label, "_Broad")]] <- celltype_conversion$CellType_Broad[
      match(final_label_values, celltype_annotation_values)
    ]
    query_obj@meta.data[[paste0(final_label, "_No_Abbreviations")]] <- celltype_conversion$CellType_No_Abbreviations[
      match(final_label_values, celltype_annotation_values)
    ]
  }
  return(query_obj)
}

#' Predict Pseudotime - Seurat v5 compatible version
#' Uses 'umap_projected' reduction name
#'
predict_Pseudotime_v5 <- function(query_obj, ref_obj, pseudotime_label = "Pseudotime",
                                   k = 30, mapQC_class = "mapping_error_QC",
                                   initial_label = "initial_Pseudotime",
                                   final_label = "predicted_Pseudotime") {
  if (!pseudotime_label %in% colnames(ref_obj$meta_data)) {
    stop(paste0("Label \"", pseudotime_label, "\" is not available in the reference metadata."))
  }

  ref_pseudotime <- ref_obj$meta_data[pseudotime_label] %>% data.matrix()

  # Use umap_projected instead of umap
  query_nn <- BiocNeighbors::queryKNN(
    X = ref_obj$umap$embedding,
    query = query_obj@reductions$umap_projected@cell.embeddings,
    k = k
  )

  query_obj@meta.data[[initial_label]] <- apply(query_nn$index, 1, function(x) {
    median(ref_pseudotime[x, ])
  })

  if (is.null(mapQC_class) || is.na(mapQC_class)) {
    query_obj@meta.data[[final_label]] <- query_obj@meta.data[[initial_label]]
  } else {
    query_obj@meta.data[[final_label]] <- ifelse(
      query_obj@meta.data[[mapQC_class]] %in% c("Fail", "fail"),
      NA,
      query_obj@meta.data[[initial_label]]
    )
  }
  return(query_obj)
}

message("BoneMarrowMap Seurat v5 compatibility patch loaded")
