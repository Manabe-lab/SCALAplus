#' Fine classifier (Modified - minimal implementation)
#'
#' This performs a fine-level annotation of HSPC cell types using single cell
#' RNA-sequencing references with configurable query reduction.
#'
#' @param input A SingleCellExperiment or Seurat object
#' @param reference Either "WT" or "5FU" (default: "WT")
#' @param query.reduction Name of reduction to use in query object (default: "pca")
#' @param return.full Whether to return full predictions directly (default: FALSE)
#' @returns An object of the same type as input with added annotations, or a dataframe with classifier results
#' @export
fine_classify <- function(input, reference = "WT", query.reduction = "pca", return.full = FALSE) {
  
  # Explicitly get HemaScribeData
  HemaScribeData <- HemaScribe:::HemaScribeData
  
  if (inherits(input, "Seurat")) {
    seurat <- input
  } else if (inherits(input, "SingleCellExperiment")) {
    seurat <- SeuratObject::as.Seurat(input)
  } else {
    stop("Only SingleCellExperiment and Seurat formats are supported.")
  }

  if (!("data" %in% SeuratObject::Layers(seurat))) {
    stop("Layer 'data' not available in Seurat object. Please normalize data first.")
  }
  
  # Check if specified reduction exists
  if (!(query.reduction %in% names(seurat@reductions))) {
    stop(paste("Reduction '", query.reduction, "' not found in Seurat object. Available reductions: ", 
               paste(names(seurat@reductions), collapse = ", ")))
  }

  if (!(reference %in% c("WT", "5FU"))) {
    stop("Reference must be one of 'WT' or '5FU'.")
  }
  if (reference == "WT") {
    ref <- HemaScribeData$ref.sc.wt
  } else if (reference == "5FU") {
    ref <- HemaScribeData$ref.sc.5fu
  }

  if (startsWith(rownames(seurat)[1], "ENSMUSG")) {
    rownames(ref@assays$integrated@data) <- translate(rownames(ref@assays$integrated@data))
    rownames(ref@assays$integrated@scale.data) <- translate(rownames(ref@assays$integrated@scale.data))
    ref@assays$integrated@var.features <- translate(ref@assays$integrated@var.features)
    rownames(ref@assays$integrated@meta.features) <- translate(rownames(ref@assays$integrated@meta.features))
    rownames(ref@reductions$pca@feature.loadings) <- translate(rownames(ref@reductions$pca@feature.loadings))
  }

  # If query.reduction is not "pca", temporarily rename it
  renamed <- FALSE
  original_name <- NULL
  existing_pca_name <- NULL
  
  if (query.reduction != "pca") {
    # If existing pca exists, rename to backup name
    if ("pca" %in% names(seurat@reductions)) {
      existing_pca_name <- "pca_temp_backup"
      names(seurat@reductions)[names(seurat@reductions) == "pca"] <- existing_pca_name
    }
    
    # Rename query.reduction to pca
    names(seurat@reductions)[names(seurat@reductions) == query.reduction] <- "pca"
    
    renamed <- TRUE
    original_name <- query.reduction
  }

  # Run FindTransferAnchors
  anchors <- Seurat::FindTransferAnchors(
    reference = ref,
    query = seurat,
    dims = 1:30,
    reference.reduction = "pca",
    verbose = FALSE
  )

  pred <- Seurat::TransferData(
    anchorset = anchors,
    refdata = ref$MULTI_ID,
    dims = 1:30,
    verbose = FALSE
  )
  pred$predicted.id[pred$predicted.id == "CFUE"] <- "EryP"

  # Restore original names
  if (renamed) {
    # Restore pca to original name
    names(seurat@reductions)[names(seurat@reductions) == "pca"] <- original_name
    
    # Restore backed up pca if exists
    if (!is.null(existing_pca_name)) {
      names(seurat@reductions)[names(seurat@reductions) == existing_pca_name] <- "pca"
    }
  }

  if (return.full) {
    return(pred)
  }

  if (inherits(input, "Seurat")) {
    seurat <- Seurat::AddMetaData(seurat, metadata = pred$predicted.id, col.name = "fine.annot")
    return(seurat)
  } else if (inherits(input, "SingleCellExperiment")) {
    input$fine.annot <- pred$predicted.id
    return(input)
  }
}

#' Two-stage classifier (Modified)
#'
#' This first performs the broad annotation of bone marrow cell types and then
#' applies the fine annotation to the cells that are annotated as HSPC.
#'
#' @param input A SingleCellExperiment or Seurat object
#' @param prefilter Hematopoietic score threshold below which cells shall be excluded (default: 0)
#' @param reference Either "WT" or "5FU" (default: "WT")
#' @param query.reduction Name of reduction to use for fine classification (default: "pca")
#' @param return.full Whether to return full predictions directly (default: FALSE)
#' @returns An object of the same type as input with added annotations, or dataframes with classifier results
#' @export
HemaScribe <- function(input, prefilter = 0, reference = "WT", query.reduction = "pca", return.full = FALSE) {
  
  # Pre-processing to avoid SCE conversion errors
  if (inherits(input, "Seurat")) {
    rlang::inform(paste("Preprocessing for", query.reduction, "reduction"))

    # Replace var.features with appropriate gene set based on integration method
    if (grepl("harmony", query.reduction, ignore.case = TRUE) && "pca" %in% names(input@reductions)) {
      # For harmony: use PCA genes
      integ_features <- rownames(input@reductions$pca@feature.loadings)
      input@assays$RNA@var.features <- integ_features
      rlang::inform(paste("Using", length(integ_features), "integration features (from PCA) for SCE conversion"))
    } else if (grepl("mnn", query.reduction, ignore.case = TRUE) && query.reduction %in% names(input@reductions)) {
      # For mnn: use mnn reduction genes
      mnn_features <- rownames(input@reductions[[query.reduction]]@feature.loadings)
      input@assays$RNA@var.features <- mnn_features
      rlang::inform(paste("Using", length(mnn_features), "MNN features for SCE conversion"))
    }

    # Remove problematic assays to avoid altExps errors (common for all cases)
    input@assays <- input@assays["RNA"]
  }
  
  rlang::inform("Calculating hematopoietic scores")
  hem.scores <- hematopoietic_score(input)

  rlang::inform("Classifying into broad cell types")
  input.hem <- input[,which(hem.scores$hematopoietic.score >= prefilter)]
  annotation.broad <- broad_classify(input.hem, return.full = TRUE)

  rlang::inform("Classifying into fine cell subtypes")
  input.hspc <- input.hem[,which(annotation.broad$pruned.labels == "HSPC")]
  skip.fine <- (ncol(input.hspc) < 30)
  if (!skip.fine) {
    annotation.fine <- fine_classify(input.hspc, reference = reference, 
                                   query.reduction = query.reduction, 
                                   return.full = TRUE)
  } else {
    rlang::warn("Not enough HSPCs. Skipping fine annotation.")
  }

  rlang::inform("Returning final annotations")
  if (!skip.fine) {
    annotations.combined <- merge(annotation.broad["pruned.labels"], annotation.fine["predicted.id"], by=0, all.x=TRUE)

    rownames(annotations.combined) <- annotations.combined$Row.names
    annotations.combined$Row.names <- NULL
  } else {
    annotations.combined <- annotation.broad["pruned.labels"]
  }

  annotations.combined <- merge(hem.scores["hematopoietic.score"], annotations.combined, by=0, all.x=TRUE)
  rownames(annotations.combined) <- annotations.combined$Row.names
  annotations.combined$Row.names <- NULL

  if (!skip.fine) {
    colnames(annotations.combined) <- c("hematopoietic.score", "broad.annot", "fine.annot")
  } else {
    colnames(annotations.combined) <- c("hematopoietic.score", "broad.annot")
  }

  annotations.combined$broad.annot[is.na(annotations.combined$broad.annot)] <- "NotHem"

  if (!skip.fine) {
    annotations.combined$fine.annot[is.na(annotations.combined$fine.annot)] <- "NotHSPC"

    annotations.combined$combined.annot <- annotations.combined$fine.annot
    not.hspc <- (annotations.combined$fine.annot == "NotHSPC")
    annotations.combined$combined.annot[not.hspc] <- annotations.combined$broad.annot[not.hspc]
    annotations.combined$combined.annot[annotations.combined$combined.annot == "GMP"] <- "mGMP"

    annotations.combined$HSPC.annot <- annotations.combined$fine.annot
    combined.renaming <- list(CLP = "CLP", cMoP = "GMP", EryP = "EryP", mGMP = "GMP", GP = "GMP", Megakaryocyte = "MkP")
    for (nm in names(combined.renaming)) {
      annotations.combined$HSPC.annot[which(annotations.combined$broad.annot == nm)] <- combined.renaming[[nm]]
    }

    annotations.combined$GMP.annot <- "NotGMP"
    annotations.combined$GMP.annot[which(annotations.combined$broad.annot == "cMoP")] <- "cMoP"
    annotations.combined$GMP.annot[which(annotations.combined$broad.annot == "GMP")] <- "mGMP"
    annotations.combined$GMP.annot[which(annotations.combined$broad.annot == "GP")] <- "GP"
    annotations.combined$GMP.annot[which(annotations.combined$fine.annot == "GMP")] <- "mGMP"
  }

  if (return.full) {
    if (!skip.fine) {
      return(list(hem.scores = hem.scores, broad = annotation.broad, fine = annotation.fine, combined = annotations.combined))
    } else {
      return(list(hem.scores = hem.scores, broad = annotation.broad, fine = NA, combined = annotations.combined))
    }
  }

  if (inherits(input, "SingleCellExperiment")) {
    input$hem.score <- annotations.combined$hematopoietic.score
    input$broad.annot <- annotations.combined$broad.annot
    if (!skip.fine) {
      input$fine.annot <- annotations.combined$fine.annot
      input$combined.annot <- annotations.combined$combined.annot
      input$HSPC.annot <- annotations.combined$HSPC.annot
      input$GMP.annot <- annotations.combined$GMP.annot
    }
    return(input)
} else if (inherits(input, "Seurat")) {
    # Verify cell names and match order
    cell_names <- colnames(input)

    # Verify row names of annotations.combined match cell names
    if (!all(rownames(annotations.combined) %in% cell_names)) {
      stop("Cell names mismatch between input and annotations")
    }

    # Match order
    annotations.combined <- annotations.combined[cell_names, , drop = FALSE]

    # Add each column
    for (col_name in colnames(annotations.combined)) {
      metadata_vector <- annotations.combined[[col_name]]
      names(metadata_vector) <- cell_names
      
      input <- Seurat::AddMetaData(
        object = input, 
        metadata = metadata_vector, 
        col.name = col_name
      )
    }
    return(input)
}
}