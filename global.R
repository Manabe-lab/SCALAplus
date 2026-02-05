library(shinydashboard)
library(DT)
library(shiny)
library(shinyjqui)
library(shinyjs)
library(shinycssloaders)
library(shinyalert)
library(SeuratObject)
library(Seurat)
#library(Seurat, lib.loc="/usr/local/lib/R/Seurat4")
# Default to v5 (can be changed per-input in DATA INPUT tab)
options(Seurat.object.assay.version = "v5")
library(plotly)
library(igraph)
library(rgl)
library(RColorBrewer)
library(dplyr)
library(visNetwork)
library(heatmaply)
library(gprofiler2)
library(ggplot2)
library(ggpubr)
library(CIPR) # devtools::install_github("atakanekiz/CIPR-Package", build_vignettes = F)
library(dittoSeq) # BiocManager::install("dittoSeq")
#library(slingshot) # BiocManager::install("slingshot")
#library(nichenetr) # devtools::install_github("saeyslab/nichenetr") # BiocManager::install("limma")
library(tidyverse)
library(destiny) #remotes::install_github("theislab/destiny")
#library(UCell) #remotes::install_github("carmonalab/UCell")
library(colorspace)
library(missMDA)
library(dismo)
#library(DoubletFinder)
#library(phateR)
#ATAC libraries
#library(ArchR)
#library(pheatmap)
library(GSEABase)
library(stringr)
library(readr)
library(parallel)
#library(chromVAR)
#library(chromVARmotifs)
library(reticulate)
use_condaenv("r-scvi")
#use_python("/home/cellxgene/anaconda3/bin/python", required = T)
#library(JASPAR2022)
#library(JASPAR2020)
#library(JASPAR2018)
#library(JASPAR2016)
library(sceasy)
library(shinyFiles)

#library(future)
#plan("multisession", workers = 4)
#plan()


#Global variables
YEAR <- substr(Sys.Date(), 1, 4)
user_dir <- "" #user's folder in temp
user_dir_pyscenic <- "" #user's folder for pyscenic results

#tab Upload
seurat_object <- NULL
init_seurat_object <- NULL
#my_metadata <- NULL
minimum_cells <- 3
minimum_features <- 200
organism <- "mouse" #or human

#tab Quality Control
qc_minFeatures <- 500
qc_maxFeatures <- 6000
qc_maxMtPercent <- 10

#tab Normalization
normalize_normMethod <- "LogNormalize"
normalize_normScaleFactor <- 10000
normalize_hvgMethod <- "vst"
normalize_hvgNGenes <- 2000
normalize_scaleRegressOut <- NULL

#tab Clustering
snn_dims <- 15
snn_k <- 20
cluster_res <- 0.6
cluster_dims <- 15

#tab DEA
markers_test <- "wilcox"
markers_minPct <- "0.1"
markers_minLogfc <- "0.25"
markers_minPval <- "0.01"
markers_logFCBase <- "avg_logFC"

#tabs Umap/tsne, DEA, Cell cycle, Trajectory
reductions_choices <- c("-")

#export tables RNA
export_metadata_RNA <- ""
export_loadingScoresTable_RNA <- ""
export_clustertable_RNA <- ""
export_markerGenes_RNA <- ""
export_enrichedTerms_RNA <- ""
export_annotation_RNA <- ""
export_ligandReceptor_full_RNA <- ""
export_ligandReceptor_short_RNA <- ""


#ATAC variables
ArrowFiles <- NULL
proj_default <- NULL
#export tables
export_metadata_ATAC <- ""
export_clustertable_ATAC <- ""
export_markerGenes_ATAC <- ""
export_markerPeaks_ATAC <- ""
export_motifs_ATAC <- ""
export_positiveRegulators_ATAC <- ""
export_peakToGenelinks_ATAC <- ""
export_PeakMotifTable_ATAC <- ""

userMode <- FALSE

if(userMode == F)
{
  #to improve speed
}

js.enrich <- "
  shinyjs.Enrich = function(url) {
    window.open(url[0]);
  }
"

# Functions ####

# This is a void function that hides all shiny css loaders
hideAllLoaders <- function(){
  shinyjs::hide("hvgScatter_loader")
  shinyjs::hide("nFeatureViolin_loader")
  shinyjs::hide("totalCountsViolin_loader")
  shinyjs::hide("mitoViolin_loader")
  shinyjs::hide("genesCounts_loader")
  shinyjs::hide("mtCounts_loader")
  shinyjs::hide("filteredNFeatureViolin_loader")
  shinyjs::hide("filteredTotalCountsViolin_loader")
  shinyjs::hide("filteredMitoViolin_loader")
  shinyjs::hide("filteredGenesCounts_loader")
  shinyjs::hide("filteredMtCounts_loader")
  shinyjs::hide("TSS_plot_loader")
  shinyjs::hide("nFrag_plot_loader")
  shinyjs::hide("TSS_nFrag_plot_loader")
  shinyjs::hide("elbowPlotPCA_loader")
  shinyjs::hide("PCAscatter_loader")
  shinyjs::hide("PCAloadings_loader")
  shinyjs::hide("PCAheatmap_loader")
  shinyjs::hide("clusterBarplot_loader")
  shinyjs::hide("clusterBarplotATAC_loader")
  shinyjs::hide("umapPlot_loader")
  shinyjs::hide("umapPlotATAC_loader")
  shinyjs::hide("findMarkersHeatmap_loader")
  shinyjs::hide("findMarkersDotplot_loader")
  shinyjs::hide("findMarkersFeaturePlot_loader")
  shinyjs::hide("findMarkersFPfeature1_loader")
  shinyjs::hide("findMarkersFPfeature2_loader")
  shinyjs::hide("findMarkersFPfeature1_2_loader")
  shinyjs::hide("findMarkersFPcolorbox_loader")
  shinyjs::hide("findMarkersViolinPlot_loader")
  shinyjs::hide("findMarkersVolcanoPlot_loader")
  shinyjs::hide("findMarkersFeaturePlotATAC_loader")
  shinyjs::hide("snnSNN_loader")
  shinyjs::hide("findMarkersGenesHeatmapATAC_loader")
  shinyjs::hide("findMarkersGenesATACTable_loader")
  shinyjs::hide("findMarkersPeaksATACTable_loader")
  shinyjs::hide("findMarkersPeaksHeatmapATAC_loader")
  shinyjs::hide("doubletATAC_loader3")
  shinyjs::hide("doubletATAC_loader4")
  shinyjs::hide("cellCyclePCA_loader")
  shinyjs::hide("cellCycleBarplot_loader")
  shinyjs::hide("gProfilerManhattan_loader")
  shinyjs::hide("findMotifsHeatmapATAC_loader")
  shinyjs::hide("findMotifsATACTable_loader")
  shinyjs::hide("annotateClustersCIPRDotplot_loader")
  shinyjs::hide("annotateClustersUMAP_loader")
  shinyjs::hide("ligandReceptorFullHeatmap_loader")
  shinyjs::hide("ligandReceptorCuratedHeatmap_loader")
  shinyjs::hide("trajectoryPlot_loader")
  shinyjs::hide("trajectoryPseudotimePlot_loader")
  shinyjs::hide("trajectoryPseudotimePlotATAC_loader")
  shinyjs::hide("grnHeatmapRNA_loader")
  shinyjs::hide("grnHeatmapATAC_loader")
  shinyjs::hide("grnATACTable_loader")
  shinyjs::hide("grnATACTable2_loader")
  shinyjs::hide("grnATACTable3_loader")
  shinyjs::hide("visualizeTracksOutput_loader")
}

#gProfiler
#set_base_url("http://biit.cs.ut.ee/gprofiler_archive3/e102_eg49_p15")

# 最初に従来のファイルを削除する
files_to_delete <- dir(pattern="*.pdf")
print("PDF files")
print(files_to_delete)

file.remove(files_to_delete)

# 関数ベタ書き-------------------

RunFastMNN2 <- function(
  object.list,
  assay = NULL,
  features = 2000,
  reduction.name = "mnn",
  reduction.key = "mnn_",
  reconstructed.assay = "mnn.reconstructed",
  verbose = TRUE,
  ...
) {
  if (length(x = object.list) < 2) {
    stop("'object.list' must contain multiple Seurat objects for integration",
         call. = FALSE)
  }
  #assay <- assay %||% DefaultAssay(object = object.list[[1]])
  for (i in 1:length(x = object.list)) {
    DefaultAssay(object = object.list[[i]]) <- assay
  }
  if (is.numeric(x = features)) {
    if (verbose) {
      message(paste("Computing", features, "integration features"))
    }
    features <- SelectIntegrationFeatures(
      object.list = object.list,
      nfeatures = features,
      assay = rep(assay, length(x = object.list))
    )
  }

  print('aaaaaa')
objects.sce <- lapply(X = object.list, FUN = function(x,f) {
#if (DefaultAssay(x) == 'SCT') {
  if (assay == 'SCT') {
x = DietSeurat(subset(x = x, features = f), assays = assay) #DietSeuratのエラー回避
indx <- match(rownames(x@assays$SCT@counts),rownames(x@assays$SCT@scale.data))
x@assays$SCT@scale.data <- x@assays$SCT@scale.data[indx,]
} else {
x = DietSeurat( subset(x = x, features = f), assays = assay ) # DietSeuratのエラー回避
}
return(as.SingleCellExperiment(x))
}, f = features)

  print('bbbbbb')

  integrated <- merge(
    x = object.list[[1]],
    y = object.list[2:length(x = object.list)]
  )
  out <- do.call(
    what = batchelor::fastMNN,
    args = c(
      objects.sce,
      list(...)
    )
  )
  rownames(x = SingleCellExperiment::reducedDim(x = out)) <- colnames(x = integrated)
  colnames(x = SingleCellExperiment::reducedDim(x = out)) <- paste0(reduction.key, 1:ncol(x = SingleCellExperiment::reducedDim(x = out)))
  integrated[[reduction.name]] <- CreateDimReducObject(
    embeddings = SingleCellExperiment::reducedDim(x = out),
    loadings = as.matrix(SingleCellExperiment::rowData(x = out)),
    assay = DefaultAssay(object = integrated),
    key = reduction.key
  )
  # Add reconstructed matrix (gene x cell)
#  options(Seurat.object.assay.version = "v3")
  integrated[[reconstructed.assay]] <- CreateAssayObject(
    data = as(object = SummarizedExperiment::assay(x = out), Class = "sparseMatrix"),
  )

  # Add variable features
  VariableFeatures(object = integrated[[reconstructed.assay]]) <- features
  Tool(object = integrated) <- S4Vectors::metadata(x = out)
  integrated <- LogSeuratCommand(object = integrated)

#  options(Seurat.object.assay.version = "v5")
  return(integrated)
}


#---------------------------------

########################  library("SCOPfunctions") これではエラーになるので直接関数ベタ書き
.FoldChange.default <- function(
  data,
  cells.1,
  cells.2,
  mean.fxn,
  fc.name,
  features = NULL,
  ...
) {

  features <- if (is.null(features)) rownames(data) else features
  # Calculate percent expressed
  thresh.min <- 0
  pct.1 <- round(
    x = rowSums(x = data[rownames(data) %in% features, colnames(data) %in% cells.1, drop = FALSE] > thresh.min) /
      length(x = cells.1),
    digits = 3
  )
  pct.2 <- round(
    x = rowSums(x = data[rownames(data) %in% features, colnames(data) %in% cells.2, drop = FALSE] > thresh.min) /
      length(x = cells.2),
    digits = 3
  )
  # Calculate fold change
  data.1 <- mean.fxn(data[rownames(data) %in% features, colnames(data) %in% cells.1, drop = FALSE])
  data.2 <- mean.fxn(data[rownames(data) %in% features, colnames(data) %in% cells.2, drop = FALSE])
  fc <- (data.1 - data.2)
  fc.results <- as.data.frame(x = cbind(fc, pct.1, pct.2))
  colnames(fc.results) <- c(fc.name, "pct.1", "pct.2")
  return(fc.results)
}


DE_MAST_RE_seurat = function(
  object,
  random_effect.vars,
  ident.1 = NULL,
  ident.2 = NULL,
  cells.1 = NULL,
  cells.2 = NULL,
  group.by = NULL,
  logfc.threshold = 0.25,
  base = exp(1),
  assay=NULL,
  slot="data",
  features = NULL,
  min.pct = 0.1,
  max.cells.per.ident = NULL,
  random.seed = 1,
  latent.vars = NULL,
  n_cores=NULL,
  verbose=TRUE,
  p.adjust.method="fdr",
  ...
) {

  # require(Seurat)
  # require(MAST)

  if (!is.null(n_cores)) {
    # https://www.tidyverse.org/blog/2020/04/self-cleaning-test-fixtures/#the-onexit-pattern
    # set new value and capture old in op
    op <- options("mc.cores"=n_cores)
    on.exit(options(op), add = T)
  }

  if (is.null(c(ident.1, ident.2, cells.1, cells.2))) stop("at least one of ident.1, ident.2, cells.1, cells.2 must be provided")
  if (!is.null(ident.1) & !is.null(cells.1)) stop("Provide one of ident.1 or cells.1 but not both")
  if (!is.null(ident.2) & !is.null(cells.2)) stop("Provide one of ident.2 or cells.2 but not both")

  fc.name  <- if (base == exp(1)) "avg_logFC" else paste0("avg_log", base, "FC")
  #======== check inputs ========================================

  stopifnot(!is.null(random_effect.vars))
  stopifnot(all(random_effect.vars %in% colnames(object@meta.data)))

  if (slot != "data") warning(paste0("MAST uses the logNormalised counts which are usually in the 'data' slot, but you are using ",slot))

  if (verbose) message(paste0("using ", round(base,2), " as log base. Make sure that the data slot has been log-transformed using this base"))
  #======== resolve idents and get cells ===================

  anyNA = if (!is.null(group.by)) any(is.na(object@meta.data[[group.by]])) else any(is.na(Seurat::Idents(object)))
  if (anyNA) stop("Some identities are NA, please check the metadata")

  logical.cells.1 = if (!is.null(cells.1)) colnames(object) %in% cells.1 else { if (!is.null(group.by)) {object@meta.data[[group.by]] == ident.1} else {Seurat::Idents(object) == ident.1}}
  if (sum(logical.cells.1)==0) {
    stop("no cells found matching ident.1. Did you forget to set Idents(object) or use group.by?")
  }
  if (is.null(cells.1)) cells.1 = colnames(object)[logical.cells.1]

  logical.cells.2 = if (!is.null(cells.2)) colnames(object) %in% cells.2 else {if (is.null(ident.2)) {!logical.cells.1} else {if (!is.null(group.by)) {object@meta.data[[group.by]] == ident.2} else {Seurat::Idents(object) == ident.2}}}
  if (sum(logical.cells.2)==0) {
    stop("no cells found matching ident.2. Did you forget to set Idents(object) or use group.by?")
  }
  if (is.null(cells.2)) cells.2 = colnames(object)[logical.cells.2]

  #======== features =================================

  features <- if (is.null(features)) rownames(object) else features

  if (any(!features %in% rownames(object))) {
    warning(paste0(paste(features[!features %in% rownames(object)], collapse = ", "), " not found in data!"))
  }

  features = features[features %in% rownames(object)]
  vec_logical_features = rep(T, length(features))

  data = Seurat::GetAssayData(object = object, assay=assay, layer=slot)

  densemat = utils_big_as.matrix(data, n_slices_init = 1, verbose=F)

  # compute average log fold change
  pseudocount.use = 1
  mean.fxn = function(x) {
    return(log(x = rowMeans(x = expm1(x = x)) + pseudocount.use, base = base))
  }
  # outputs a data.frame with columns fc.name, "pct.1", "pct.2"
  fc.results = .FoldChange.default(
      data=densemat,
      cells.1=cells.1,
      cells.2=cells.2,
      mean.fxn=mean.fxn,
      fc.name=fc.name,
      features = features)

  if (!is.null(logfc.threshold)) {
    vec_logical_features = vec_logical_features & fc.results[[fc.name]]>logfc.threshold  # need to convert back to non-log space to take mean
  }
  if (sum(vec_logical_features)<2) stop(paste0("Fewer than two features have a log fold change above ", logfc.threshold))
  if (!is.null(min.pct)) {
    vec_logical_features = vec_logical_features & (fc.results$pct.1 > min.pct | fc.results$pct.2 > min.pct)
  }
  if (sum(vec_logical_features)<2) stop(paste0("Fewer than two features are expressed in ", min.pct, " of cells in any condition"))

  features <- features[vec_logical_features]

  densemat = densemat[rownames(densemat) %in% features, , drop=F]

  #======== down sample cells ==============================

  idx.cells.1 = which(logical.cells.1)
  idx.cells.2 = which(logical.cells.2)

  if (!is.null(max.cells.per.ident)) {
    if (sum(logical.cells.1) > max.cells.per.ident) {
      set.seed(randomSeed)
      idx.cells.1 = sample(x = idx.cells.1, size = max.cells.per.ident, replace = F)
    }
    if (sum(!logical.cells.1) > max.cells.per.ident) {
      set.seed(randomSeed)
      idx.cells.2 = sample(x = idx.cells.2, size = max.cells.per.ident, replace = F)
    }
  }

  cells.1 = colnames(densemat)[idx.cells.1]
  cells.2 = colnames(densemat)[idx.cells.2]
  densemat = densemat[,c(idx.cells.1,idx.cells.2), drop=F]

  #======== filter out all zero features (if not already removed) ==

  densemat = densemat[apply(X = densemat, MARGIN=1, FUN = sum)>0,]

  #======== prep column (cell/sample) data =================

  df_coldata = data.frame(
    row.names = c(cells.1, cells.2),
    "wellKey" = c(cells.1, cells.2)
    ) # wellKey is hardcoded feature name in MAST

  # DE group factor
  df_coldata[cells.1, "group"] <- "Group1"
  df_coldata[cells.2, "group"] <- "Group2"
  df_coldata[, "group"] <- factor(x = df_coldata[, "group"])

  # latent vars
  if (!is.null(latent.vars)) {
    for (latent.var in latent.vars) {
      df_coldata[[latent.var]] <- object@meta.data[c(idx.cells.1,idx.cells.2), latent.var]
    }
  }

  # add random vars to column data
  for (random_effect.var in random_effect.vars) {
    df_coldata[[random_effect.var]] <- as.factor(
        object@meta.data[c(idx.cells.1,idx.cells.2),random_effect.var]
      )
  }

  # check for NAs in column data
  for (colname in colnames(df_coldata)) {
    if (any(is.na(df_coldata[[colname]]))) {
      stop(paste0("variable '", colname, "' contains NAs"))
    }
  }

  # check whether random var levels overlap entirely with test condition
  for (random_effect.var in random_effect.vars) {
    for (re_lvl in levels(df_coldata[[random_effect.var]])) {
      if (all(df_coldata[[random_effect.var]]==re_lvl & 1:ncol(densemat) %in% idx.cells.1)) {
        stop(paste0(random_effect.var, " level ", re_lvl, " overlaps entirely with ident.1. Increase ", max.cells.per.ident, " or check the data"))
      }
      else if (all(df_coldata[[random_effect.var]]==re_lvl & 1:ncol(densemat) %in% idx.cells.2)) {
        stop(paste0(random_effect.var, " level ", re_lvl, " overlaps entirely with ident.2. Increase ", max.cells.per.ident, " or check the data"))
      }
    }
  }

  #======== prep  feature data =========================

  df_feature = data.frame("primerid"=rownames(densemat)) # primerid is hardcoded feature name in MAST

  #======== prep SingleCellAssay object ============================

  expr = quote(MAST::FromMatrix(exprsArray=densemat,
                                 check_sanity = TRUE,
                                 cData=df_coldata,
                                 fData=df_feature))
  sca <- if (verbose) eval(expr) else suppressMessages(eval(expr))

  SummarizedExperiment::colData(sca)$group <- relevel(SummarizedExperiment::colData(sca)$group, ref="Group2")


  #======== run MAST test ======================

  str_plus = if (!is.null(latent.vars)) " + " else ""

  fmla <- as.formula(
    object = paste0(" ~ group", str_plus, paste(latent.vars, collapse = " + "), paste(" + (1 |", random_effect.vars, ")", collapse=""))
  )

  # fit model parameters
  expr = quote(MAST::zlm(formula = fmla,
                   sca = sca,
                   method = 'glmer',
                   ebayes = F,
                   strictConvergence = FALSE,
                   ...))

  zlmCond <- if (verbose) eval(expr) else suppressMessages(eval(expr))

  if (verbose) {
    print(zlmCond)
    message("Compute likelihoods and p-values")
  }
  # call a likelihood ratio test on the fitted object
  expr = quote(MAST::summary(object = zlmCond, doLRT = 'groupGroup1'))
  summaryCond <- if (verbose) eval(expr) else suppressWarnings(suppressMessages(eval(expr)))

  if ("character" %in% class(summaryCond)) stop("No differentially genes detected")


  de.results <- data.frame(
    "p_val" = summaryCond$datatable[contrast=='groupGroup1' & component=='H', `Pr(>Chisq)`],
    fc.results[vec_logical_features,])  #setDF(summaryCond$datatable[contrast=='groupGroup1' & component=='logFC', .(coef)])

  de.results$p_val_adj = p.adjust(de.results$p_val, method=p.adjust.method, n=length(vec_logical_features))

  de.results = de.results[order(de.results$p_val, -de.results[[fc.name]]),]

  return(de.results)
}


.countsperclus <- function(
  object,
  group,
  assay=NULL,
  slot=NULL,
  min.cell=100) {

  if(is.null(group)) {
    vec_group <- factor(as.character(Seurat::Idents(object)))
  } else {
    vec_group <- factor(object@meta.data[[group]])
  }
  mat.sparse <- Seurat::GetAssayData(object, assay=assay, layer=slot)
  mm <- stats::model.matrix(~ 0 + vec_group)
  colnames(mm) <- paste0("clus_", levels(vec_group))
  mm <- mm[,colSums(mm)>min.cell]
  mat.sum <- mat.sparse %*% mm
  keep <-  Matrix::rowSums(mat.sum > 0) >= ncol(mat.sum)/3
  mat.sum <- mat.sum[keep, ]
  return(mat.sum)
}


 DE_calcWLO <- function(
  object,
  uninformative=TRUE,
  group= NULL,
  id1 = NULL,
  id2 = NULL,
  assay = NULL,
  slot = NULL,
  lower.tail=FALSE,
  p.adj.method="fdr",
  ...) {

  cpg <- .countsperclus(
    object=object,
    group = group,
    assay = assay,
    slot = slot,
    ...)

  cpg %>%
    as.data.frame() %>%
    tibble::rownames_to_column("gene") %>%
    tidyr::pivot_longer(-gene) %>%
    dplyr::rename(group = name) %>%
    dplyr::mutate(group = as.factor(group)) ->
    cpg

  if (!is.null(id1)) {
    if (is.null(id2)) {
      # contrast id1 with all other cells
      id1 <- paste0("clus_", id1)
      cpg %>%
        dplyr::mutate(group = dplyr::if_else(group == id1, "group_1", "group_2")) %>%
        dplyr::group_by(gene, group) %>%
        dplyr::summarise(value = sum(value)) ->
        cpg
    } else {
      # contrast id2 with id2
      id1 <- paste0("clus_", id1)
      id2 <- paste0("clus_", id2)
      cpg %>%
        dplyr::mutate(group = dplyr::case_when(group %in% id1 ~ "group_1",
                                 group %in% id2 ~ "group_2",
                                 T ~ "remove")) %>%
        dplyr::group_by(gene, group) %>%
        dplyr::summarise(value = sum(value)) %>%
        dplyr::filter(group!="remove") ->
        cpg
    }
  }

  tidylo::bind_log_odds(
    tbl=cpg,
    set = group,
    feature = gene,
    n = value,
    uninformative = uninformative,
    unweighted = TRUE
    # return unweighted as well as weighted log odds
    # weighting accounts for sampling variability
    ) %>%
      # dplyr::filter(group=="group_1") %>%
      dplyr::arrange(-log_odds_weighted) ->
      dat

    dat$p_value = pnorm(q=dat$log_odds_weighted, lower.tail = lower.tail)
    dat$p_value_adj = p.adjust(dat$p_value, method = p.adj.method)

  return(dat)
}


utils_big_as.matrix <- function(
  sparseMat,
  n_slices_init=1,
  verbose=T
  ) {

  n_slices <- n_slices_init-1
  while (TRUE) {
    list_densemat = list()
    n_slices = n_slices+1
    if (verbose) message(paste0("n_slices=",n_slices))
    idx_to = 0
    for (slice in 1:n_slices) {
      if (verbose) message(paste0("converting slice ",slice,"/",n_slices))
      idx_from <- idx_to+1
      idx_to <- if (slice<n_slices) as.integer(ncol(sparseMat)*slice/n_slices) else ncol(sparseMat)
      if (verbose) message(paste0("columns ", idx_from,":", idx_to))
      densemat_sub = try(
        expr = {
          as.matrix(sparseMat[,idx_from:idx_to])
        }, silent = if (verbose) FALSE else TRUE)
      if ("try-error" %in% class(densemat_sub)) {
        break # exit to while loop
      } else {
        list_densemat[[slice]] = densemat_sub
      }
    }
    if (length(list_densemat)==n_slices) break # exit while loop
  }
  if (verbose) message("cbind dense submatrices")
  densemat <- Reduce(f=cbind, x=list_densemat)
  return(densemat)
}

.regularise_df <- function(df, drop_single_values = TRUE) {
  if (ncol(df) == 0) df[["name"]] <- rownames(df)
  if (drop_single_values) {
    k_singular <- sapply(df, function(x) length(unique(x)) == 1)
    if (sum(k_singular) > 0) {
      warning(
        paste("Dropping single category variables:"),
        paste(colnames(df)[k_singular], collapse = ", ")
      )
    }
    df <- df[, !k_singular, drop = F]
    if (ncol(df) == 0) df[["name"]] <- rownames(df)
  }
  return(df)
}

#### 改変版 dynamoへの対応
# Improved seurat2ann function with PCA loading support
# No external dependencies except Seurat, reticulate, and anndata
#
# AnnData structure overview:
# ===========================
# AnnData object stores single-cell data in a structured format:
#
# - X (matrix):           Main expression matrix [n_obs × n_vars] (cells × genes)
#                         Typically normalized/log-transformed data
#                         Stored as scipy sparse matrix (CSR format)
#
# - obs (DataFrame):      Cell-level metadata [n_obs × n_metadata]
#                         Index: cell barcodes/names
#                         Columns: cell_type, clusters, QC metrics, etc.
#
# - var (DataFrame):      Gene-level metadata [n_vars × n_metadata]
#                         Index: gene names/IDs
#                         Columns: highly_variable, gene_symbols, etc.
#
# - obsm (dict):          Cell-level multi-dimensional arrays
#                         Keys: "X_pca", "X_umap", "X_tsne", etc.
#                         Values: matrices [n_obs × n_components]
#                         Cell embeddings (PCA, UMAP, etc.)
#
# - varm (dict):          Gene-level multi-dimensional arrays
#                         Keys: "PCs" (PCA loadings), etc.
#                         Values: matrices [n_vars × n_components]
#                         Gene loadings (required for Dynamo perturbation)
#
# - uns (dict):           Unstructured metadata (any Python object)
#                         Keys: "pca_mean", "pca_stdev", "neighbors", etc.
#                         Values: arrays, dicts, or other metadata
#
# - raw (AnnData):        Raw counts before normalization
#                         raw.X: [n_obs × n_vars] sparse matrix of raw counts
#                         raw.var: gene metadata for raw data
#
# This function converts Seurat objects to AnnData format while preserving:
# - Expression data (X and raw.X)
# - Cell and gene metadata (obs, var)
# - Dimensional reductions (obsm)
# - PCA loadings for perturbation analysis (varm)
# - Additional metadata (uns)

.regularise_df <- function(df, drop_single_values = TRUE) {
  if (drop_single_values) {
    # Remove columns with single unique value
    single_val_cols <- sapply(df, function(x) length(unique(x)) == 1)
    if (any(single_val_cols)) {
      df <- df[, !single_val_cols, drop = FALSE]
    }
  }
  return(df)
}


seurat2ann <- function(obj,
                       outFile = NULL,
                       assay = "RNA",
                       main_layer = "data",
                       transfer_layers = NULL,
                       drop_single_values = TRUE,
                       full = FALSE) {

  # Seurat v5 Assay5 guard: JoinLayers() must be run first
  if (inherits(obj[[assay]], "Assay5")) {
    stop("Assay5 detected. Please run Seurat::JoinLayers() before conversion.\n",
         "Example: obj <- Seurat::JoinLayers(obj)")
  }

  main_layer <- match.arg(main_layer, c("data", "counts", "scale.data"))
  transfer_layers <- transfer_layers[
    transfer_layers %in% c("data", "counts", "scale.data")
  ]
  transfer_layers <- transfer_layers[transfer_layers != main_layer]

  # ========================================
  # Extract X: Main expression matrix
  # ========================================
  # Seurat: [genes × cells] sparse matrix
  # Will be transposed to AnnData format: [cells × genes]
  X <- Seurat::GetAssayData(object = obj, assay = assay, layer = main_layer)

  # ========================================
  # Extract obs: Cell metadata (DataFrame)
  # ========================================
  obs <- .regularise_df(obj@meta.data, drop_single_values = drop_single_values)

  # ========================================
  # Extract var: Gene metadata (DataFrame)
  # ========================================
  var <- .regularise_df(Seurat::GetAssay(obj, assay = assay)@meta.features, drop_single_values = drop_single_values)

  # Ensure obs/var order strictly matches X (genes x cells in Seurat)
  # This prevents index mismatch errors in AnnData
  obs <- obs[colnames(X), , drop = FALSE]
  var <- var[rownames(X), , drop = FALSE]

  # Add highly_variable genes (standard AnnData field)
  # Scanpy/Dynamo use this for feature selection
  hvgs <- tryCatch(
    Seurat::VariableFeatures(Seurat::GetAssay(obj, assay = assay)),
    error = function(e) character(0)
  )
  hvgs <- intersect(hvgs, rownames(var))
  var$highly_variable <- rownames(var) %in% hvgs

  # ========================================
  # Extract obsm: Cell embeddings (dict)
  # ========================================
  # Stores dimensional reductions: PCA, UMAP, tSNE, etc.
  # Keys: "X_pca", "X_umap", etc.
  obsm <- NULL
  reductions <- names(obj@reductions)
  if (length(reductions) > 0) {
    obsm <- sapply(
      reductions,
      function(name) {
        tryCatch({
          as.matrix(Seurat::Embeddings(obj, reduction = name))
        }, error = function(e) {
          warning(paste("Failed to extract embeddings for reduction:", name))
          warning(paste("Error details:", e$message))
          NULL
        })
      },
      simplify = FALSE
    )
    # Remove NULL entries
    obsm <- obsm[!sapply(obsm, is.null)]
    if (length(obsm) > 0) {
      names(obsm) <- paste0("X_", tolower(names(obsm)))
    }
  }

  # ========================================
  # Extract varm: Gene loadings (dict) - ONLY if full=TRUE
  # Extract uns: Unstructured metadata (dict) - ONLY if full=TRUE
  # ========================================
  # varm stores PCA loadings (gene × component matrices)
  # Required for Dynamo perturbation analysis to convert between
  # gene expression space and PCA space
  #
  # uns stores additional metadata (stdev, means, misc)
  varm <- NULL
  uns <- NULL

  if (full && length(reductions) > 0) {
    varm <- list()
    uns <- list()

    # Get all gene names for varm expansion
    all_genes <- rownames(var)

    for (name in reductions) {
      tryCatch({
        # Extract feature loadings using Seurat::Loadings() for version safety
        # This works across different Seurat versions
        ld <- try(Seurat::Loadings(obj[[name]]), silent = TRUE)

        if (!inherits(ld, "try-error") && !is.null(ld) &&
            nrow(ld) > 0 && ncol(ld) > 0) {
          loadings_mat <- as.matrix(ld)
          pca_genes <- rownames(loadings_mat)

          # Expand loadings to match ALL genes (AnnData varm requirement)
          # AnnData requires varm matrices to have same n_vars as X
          # Genes not used in PCA will have zero loadings
          loadings_full <- matrix(0, nrow = length(all_genes), ncol = ncol(loadings_mat))
          rownames(loadings_full) <- all_genes
          colnames(loadings_full) <- colnames(loadings_mat)

          # Fill in loadings for genes that were used in PCA
          if (!is.null(pca_genes) && length(pca_genes) > 0) {
            matched_genes <- intersect(pca_genes, all_genes)
            if (length(matched_genes) > 0) {
              loadings_full[matched_genes, ] <- loadings_mat[matched_genes, ]
            }
          }

          # Store in varm with descriptive key (e.g., "PCs_rna.pca")
          # This is the standard AnnData convention
          varm[[paste0("PCs_", tolower(name))]] <- loadings_full

          # Store PCA genes list in uns for reference
          # Useful to know which genes were actually used in PCA
          if (!is.null(pca_genes) && length(pca_genes) > 0) {
            uns[[paste0(tolower(name), "_genes")]] <- pca_genes

            # Calculate and store mean expression for PCA genes
            # Used by Dynamo for perturbation calculations
            # CRITICAL: Must expand to ALL genes to match PCs dimensions
            mat_data <- Seurat::GetAssayData(object = obj, assay = assay, layer = "data")
            if (all(pca_genes %in% rownames(mat_data))) {
              mat_subset <- mat_data[pca_genes, , drop = FALSE]
              gene_means <- Matrix::rowMeans(mat_subset)

              # Expand mean to ALL genes (same as PCs expansion)
              # This ensures dimensional consistency for perturbation: X @ PCs.T + mean
              mean_full <- rep(0, length(all_genes))
              names(mean_full) <- all_genes

              # Fill in means for genes that were used in PCA
              matched_genes_for_mean <- intersect(pca_genes, all_genes)
              if (length(matched_genes_for_mean) > 0) {
                mean_full[matched_genes_for_mean] <- gene_means[matched_genes_for_mean]
              }

              mean_key <- paste0(tolower(name), "_mean")
              uns[[mean_key]] <- mean_full
            }
          }
        }

        # Store standard deviation (PC variance) in uns
        # Important for understanding PC contribution
        stdev <- obj@reductions[[name]]@stdev
        if (length(stdev) > 0) {
          uns[[paste0(tolower(name), "_stdev")]] <- stdev
        }

        # Store any additional misc data in uns
        misc <- obj@reductions[[name]]@misc
        if (length(misc) > 0) {
          for (misc_name in names(misc)) {
            uns[[paste0(tolower(name), "_", misc_name)]] <- misc[[misc_name]]
          }
        }
      }, error = function(e) {
        # Silent fail for optional data
        # Allows conversion to continue even if some reductions lack loadings
      })
    }

      # Remove empty lists
    if (length(varm) == 0) varm <- NULL
    if (length(uns) == 0) uns <- NULL
  }

  # ========================================
  # Extract obsp: Neighbor graphs (ONLY if full=TRUE)
  # ========================================
  # obsp stores cell-cell relationship matrices (neighbors, connectivities)
  # Required for Dynamo and other velocity tools
  obsp <- NULL

  if (full) {
    obsp <- list()

    # Check for graphs in Seurat object (SNN, etc.)
    if (length(obj@graphs) > 0) {
      for (graph_name in names(obj@graphs)) {
        tryCatch({
          graph_mat <- obj@graphs[[graph_name]]
          if (!is.null(graph_mat) && inherits(graph_mat, "Matrix")) {
            # Store with standardized key names
            # Seurat uses RNA_snn, RNA_nn etc., we convert to connectivities/distances
            if (grepl("snn", tolower(graph_name))) {
              obsp[["connectivities"]] <- as.matrix(graph_mat)
            } else if (grepl("nn", tolower(graph_name)) && !grepl("snn", tolower(graph_name))) {
              # nn graph can be used as distances (inverse of weights)
              obsp[["distances"]] <- as.matrix(graph_mat)
            }
            # Also store with original name for reference
            obsp[[tolower(graph_name)]] <- as.matrix(graph_mat)
          }
        }, error = function(e) {
          # Silent fail for optional data
        })
      }
    }

    # Check for neighbors slot (newer Seurat versions)
    if (length(obj@neighbors) > 0) {
      for (nn_name in names(obj@neighbors)) {
        tryCatch({
          nn_obj <- obj@neighbors[[nn_name]]
          if (!is.null(nn_obj)) {
            # Extract nn.idx and nn.dist if available
            if ("nn.idx" %in% slotNames(nn_obj)) {
              nn_idx <- slot(nn_obj, "nn.idx")
              nn_dist <- slot(nn_obj, "nn.dist")

              if (!is.null(nn_idx) && !is.null(nn_dist)) {
                # Convert k-NN to sparse distance matrix
                n_cells <- nrow(nn_idx)
                k <- ncol(nn_idx)

                # Create sparse matrix from kNN
                i_idx <- rep(1:n_cells, each = k)
                j_idx <- as.vector(t(nn_idx))
                x_val <- as.vector(t(nn_dist))

                # Remove invalid indices (0 or NA)
                valid <- !is.na(j_idx) & j_idx > 0
                i_idx <- i_idx[valid]
                j_idx <- j_idx[valid]
                x_val <- x_val[valid]

                dist_mat <- Matrix::sparseMatrix(
                  i = i_idx, j = j_idx, x = x_val,
                  dims = c(n_cells, n_cells)
                )
                rownames(dist_mat) <- rownames(nn_idx)
                colnames(dist_mat) <- rownames(nn_idx)

                if (!"distances" %in% names(obsp)) {
                  obsp[["distances"]] <- as.matrix(dist_mat)
                }
              }
            }
          }
        }, error = function(e) {
          # Silent fail for optional data
        })
      }
    }

    if (length(obsp) == 0) obsp <- NULL
  }

  # ========================================
  # Align obsm and varm to match obs/var order
  # ========================================
  # Critical: ensures row order consistency across all AnnData components

  # Align obsm to obs (cells)
  # Each embedding matrix must have same cell order as obs
  if (!is.null(obsm) && length(obsm) > 0) {
    for (nm in names(obsm)) {
      rn <- rownames(obsm[[nm]])
      if (!is.null(rn)) {
        obsm[[nm]] <- obsm[[nm]][rownames(obs), , drop = FALSE]
      }
    }
  }

  # Align varm to var (genes)
  # Each loading matrix must have same gene order as var
  if (!is.null(varm) && length(varm) > 0) {
    for (nm in names(varm)) {
      rn <- rownames(varm[[nm]])
      if (!is.null(rn)) {
        varm[[nm]] <- varm[[nm]][rownames(var), , drop = FALSE]
      }
    }
  }

  # Align obsp to obs (cells)
  # Each neighbor matrix must have same cell order as obs
  if (!is.null(obsp) && length(obsp) > 0) {
    for (nm in names(obsp)) {
      mat <- obsp[[nm]]
      rn <- rownames(mat)
      cn <- colnames(mat)
      if (!is.null(rn) && !is.null(cn)) {
        # Reorder both rows and columns to match obs order
        cell_order <- rownames(obs)
        common_cells <- intersect(cell_order, rn)
        if (length(common_cells) > 0) {
          obsp[[nm]] <- mat[common_cells, common_cells, drop = FALSE]
        }
      }
    }
  }

  # ========================================
  # Extract raw.X: Raw counts (ONLY if "counts" specified)
  # ========================================
  # raw.X stores unnormalized counts for downstream analysis
  # IMPORTANT: Only creates raw if transfer_layers contains "counts"
  counts_t <- NULL
  if (!is.null(transfer_layers) && "counts" %in% transfer_layers) {
    cnt <- Seurat::GetAssayData(object = obj, assay = assay, layer = "counts")
    counts_t <- Matrix::t(cnt)  # Transpose: [genes × cells] → [cells × genes]
  }

  # ========================================
  # Import Python modules
  # ========================================
  anndata <- reticulate::import("anndata", convert = FALSE)
  pd <- reticulate::import("pandas", convert = TRUE)  # convert=TRUE for safer DataFrame handling
  sp <- reticulate::import("scipy.sparse", convert = FALSE)

  # ========================================
  # Convert X to scipy sparse matrix (CSR format)
  # ========================================
  # CSR (Compressed Sparse Row) format is memory-efficient for sparse data
  # and is the standard format for AnnData
  sx <- methods::as(Matrix::t(X), "TsparseMatrix")  # Transpose and convert to triplet format
  coo <- sp$coo_matrix(
    reticulate::tuple(
      reticulate::r_to_py(sx@x),  # Non-zero values
      reticulate::tuple(reticulate::r_to_py(sx@i), reticulate::r_to_py(sx@j))  # Row and column indices
    ),
    shape = reticulate::tuple(nrow(sx), ncol(sx))  # [cells × genes]
  )
  X_py <- coo$tocsr()  # Convert COO to CSR for efficient storage

  # ========================================
  # Convert obs and var to pandas DataFrame
  # ========================================
  # pandas DataFrames with proper index (cell/gene names)
  obs_pd <- pd$DataFrame(
    data  = reticulate::r_to_py(obs),
    index = reticulate::r_to_py(rownames(obs))  # Cell barcodes/names
  )

  var_pd <- pd$DataFrame(
    data  = reticulate::r_to_py(var),
    index = reticulate::r_to_py(rownames(var))  # Gene names/IDs
  )

  # ========================================
  # Convert obsm to Python dict
  # ========================================
  # obsm: dict of cell embeddings (PCA, UMAP, etc.)
  obsm_py <- NULL
  if (!is.null(obsm) && length(obsm) > 0) {
    obsm_py <- reticulate::dict()
    for (name in names(obsm)) {
      obsm_py[[name]] <- reticulate::r_to_py(obsm[[name]])
    }
  }

  # ========================================
  # Convert varm to Python dict
  # ========================================
  # varm: dict of gene loadings (PCA loadings, etc.)
  varm_py <- NULL
  if (!is.null(varm) && length(varm) > 0) {
    varm_py <- reticulate::dict()
    for (name in names(varm)) {
      varm_py[[name]] <- reticulate::r_to_py(varm[[name]])
    }
  }

  # ========================================
  # Convert uns to Python dict
  # ========================================
  # uns: dict of unstructured metadata (any object type)
  uns_py <- NULL
  if (!is.null(uns) && length(uns) > 0) {
    uns_py <- reticulate::dict()
    for (name in names(uns)) {
      uns_py[[name]] <- reticulate::r_to_py(uns[[name]])
    }
  }

  # ========================================
  # Convert obsp to Python sparse matrices
  # ========================================
  # obsp: dict of cell-cell relationship matrices (neighbors, connectivities)
  # Must be converted to scipy sparse format for AnnData
  obsp_py <- NULL
  if (!is.null(obsp) && length(obsp) > 0) {
    obsp_py <- list()
    for (name in names(obsp)) {
      mat <- obsp[[name]]
      # Convert to scipy sparse matrix (CSR format)
      if (inherits(mat, "Matrix")) {
        sx_obsp <- methods::as(mat, "TsparseMatrix")
      } else {
        # Convert dense matrix to sparse
        sx_obsp <- methods::as(Matrix::Matrix(mat, sparse = TRUE), "TsparseMatrix")
      }
      coo_obsp <- sp$coo_matrix(
        reticulate::tuple(
          reticulate::r_to_py(sx_obsp@x),
          reticulate::tuple(reticulate::r_to_py(sx_obsp@i), reticulate::r_to_py(sx_obsp@j))
        ),
        shape = reticulate::tuple(nrow(sx_obsp), ncol(sx_obsp))
      )
      obsp_py[[name]] <- coo_obsp$tocsr()
    }
  }

  # ========================================
  # Create AnnData object
  # ========================================
  # Assemble all components into AnnData structure
  adata <- anndata$AnnData(
    X = X_py,           # Main expression matrix (sparse CSR)
    obs = obs_pd,       # Cell metadata (pandas DataFrame)
    var = var_pd,       # Gene metadata (pandas DataFrame)
    obsm = obsm_py,     # Cell embeddings (dict)
    varm = varm_py,     # Gene loadings (dict)
    uns = uns_py        # Unstructured metadata (dict)
  )

  # Add obsp (neighbor matrices) after creation
  # AnnData constructor doesn't accept obsp directly
  if (!is.null(obsp_py) && length(obsp_py) > 0) {
    for (name in names(obsp_py)) {
      adata$obsp[[name]] <- obsp_py[[name]]
    }
  }

  # ========================================
  # Add raw layer - ONLY if counts specified
  # ========================================
  # raw stores unnormalized counts for differential expression, etc.
  if (!is.null(counts_t)) {
    # Convert counts to scipy sparse matrix (CSR format)
    sx_counts <- methods::as(counts_t, "TsparseMatrix")
    coo_counts <- sp$coo_matrix(
      reticulate::tuple(
        reticulate::r_to_py(sx_counts@x),
        reticulate::tuple(reticulate::r_to_py(sx_counts@i), reticulate::r_to_py(sx_counts@j))
      ),
      shape = reticulate::tuple(nrow(sx_counts), ncol(sx_counts))
    )
    counts_py <- coo_counts$tocsr()

    # Create raw AnnData object
    ad_raw <- adata$copy()
    ad_raw$X <- counts_py  # Replace X with counts
    adata$raw <- ad_raw    # Assign to raw slot
    # Note: adata.X remains as normalized data
  }

  if (!is.null(outFile)) {
    adata$write(outFile, compression = "gzip")
  }

  adata
}

###################　関数終わり

############ color palettes

  stallion = c("1"="#D51F26","2"="#272E6A","3"="#208A42","4"="#89288F","5"="#F47D2B", "6"="#FEE500","7"="#8A9FD1","8"="#C06CAB","19"="#E6C2DC",
               "10"="#90D5E4", "11"="#89C75F","12"="#F37B7D","13"="#9983BD","14"="#D24B27","15"="#3BBCA8", "16"="#6E4B9E","17"="#0C727C", "18"="#7E1416","9"="#D8A767","20"="#3D3D3D")

  stallion2 = c("1"="#D51F26","2"="#272E6A","3"="#208A42","4"="#89288F","5"="#F47D2B", "6"="#FEE500","7"="#8A9FD1","8"="#C06CAB","19"="#E6C2DC",
               "10"="#90D5E4", "11"="#89C75F","12"="#F37B7D","13"="#9983BD","14"="#D24B27","15"="#3BBCA8", "16"="#6E4B9E","17"="#0C727C", "18"="#7E1416","9"="#D8A767")

  calm = c("1"="#7DD06F", "2"="#844081", "3"="#688EC1", "4"="#C17E73", "5"="#484125", "6"="#6CD3A7", "7"="#597873","8"="#7B6FD0", "9"="#CF4A31", "10"="#D0CD47",
          "11"="#722A2D", "12"="#CBC594", "13"="#D19EC4", "14"="#5A7E36", "15"="#D4477D", "16"="#403552", "17"="#76D73C", "18"="#96CED5", "19"="#CE54D1", "20"="#C48736")

  kelly = c("1"="#FFB300", "2"="#803E75", "3"="#FF6800", "4"="#A6BDD7", "5"="#C10020", "6"="#CEA262", "7"="#817066", "8"="#007D34", "9"="#F6768E", "10"="#00538A",
          "11"="#FF7A5C", "12"="#53377A", "13"="#FF8E00", "14"="#B32851", "15"="#F4C800", "16"="#7F180D", "17"="#93AA00", "18"="#593315", "19"="#F13A13", "20"="#232C16")

  #16-colors
  bear = c("1"="#faa818", "2"="#41a30d","3"="#fbdf72", "4"="#367d7d",  "5"="#d33502", "6"="#6ebcbc", "7"="#37526d",
           "8"="#916848", "9"="#f5b390", "10"="#342739", "11"="#bed678","12"="#a6d9ee", "13"="#0d74b6",
           "14"="#60824f","15"="#725ca5", "16"="#e0598b")

  #15-colors
  ironMan = c("9"='#371377',"3"='#7700FF',"2"='#9E0142',"10"='#FF0080', "14"='#DC494C',"12"="#F88D51","1"="#FAD510","8"="#FFFF5F","4"='#88CFA4',
           "13"='#238B45',"5"="#02401B", "7"="#0AD7D3","11"="#046C9A", "6"="#A2A475", "15"='grey35')

  circus = c("1"="#D52126", "2"="#88CCEE", "3"="#FEE52C", "4"="#117733", "5"="#CC61B0", "6"="#99C945", "7"="#2F8AC4", "8"="#332288",
             "9"="#E68316", "10"="#661101", "11"="#F97B72", "12"="#DDCC77", "13"="#11A579", "14"="#89288F", "15"="#E73F74")

  #12-colors
  paired = c("9"="#A6CDE2","1"="#1E78B4","3"="#74C476","12"="#34A047","11"="#F59899","2"="#E11E26",
               "10"="#FCBF6E","4"="#F47E1F","5"="#CAB2D6","8"="#6A3E98","6"="#FAF39B","7"="#B15928")

  #11-colors
  grove = c("11"="#1a1334","9"="#01545a","1"="#017351","6"="#03c383","8"="#aad962","2"="#fbbf45","10"="#ef6a32","3"="#ed0345","7"="#a12a5e","5"="#710162","4"="#3B9AB2")
Zissou1Continuous = c("#3A9AB2", "#6FB2C1", "#91BAB6", "#A5C2A3", "#BDC881", "#DCCB4E", "#E3B710", "#E79805", "#EC7A05", "#EF5703", "#F11B00") #wesanderson

  #7-colors
  summerNight = c("1"="#2a7185", "2"="#a64027", "3"="#fbdf72","4"="#60824f","5"="#9cdff0","6"="#022336","7"="#725ca5")

  #5-colors
  zissou = c("1"="#3B9AB2", "4"="#78B7C5", "3"="#EBCC2A", "5"="#E1AF00", "2"="#F21A00") #wesanderson
  darjeeling = c("1"="#FF0000", "2"="#00A08A", "3"="#F2AD00", "4"="#F98400", "5"="#5BBCD6") #wesanderson
  rushmore = c("1"="#E1BD6D", "5"="#EABE94", "2"="#0B775E", "4"="#35274A" , "3"="#F2300F") #wesanderson
  captain = c("1"="grey","2"="#A1CDE1","3"="#12477C","4"="#EC9274","5"="#67001E")


# conversion _,-の変換によるduplicate形成に対応

anndata2seurat <- function(inFile, outFile = NULL, main_layer = "counts", assay = "RNA", use_seurat = FALSE,
                           lzf = FALSE, target_uns_keys = list(), x_to_counts = FALSE) {
  if (!requireNamespace("Seurat")) {
    stop("This function requires the 'Seurat' package.")
  }
  main_layer <- match.arg(main_layer, c("counts", "data", "scale.data"))
  inFile <- path.expand(inFile)

  anndata <- reticulate::import("anndata", convert = FALSE)
  sp <- reticulate::import("scipy.sparse", convert = FALSE)

  if (use_seurat) {
    if (lzf) {
      tmpFile <- paste0(tools::file_path_sans_ext(inFile), ".decompressed.h5ad")
      ad <- anndata$read_h5ad(inFile)
      ad$write(tmpFile)
      tryCatch(
        {
          srt <- Seurat::ReadH5AD(tmpFile)
        },
        finally = {
          file.remove(tmpFile)
        }
      )
    } else {
      srt <- Seurat::ReadH5AD(inFile)
    }
  } else {
    ad <- anndata$read_h5ad(inFile)

    obs_df <- .obs2metadata(ad$obs)
    var_df <- .var2feature_metadata(ad$var)

    # seuratへの読み込みの際に、_を-に変換するときにduplicate nameになるときの対応
names <- row.names(var_df)
new_names <- str_replace_all(names, '_', '-')
if (sum(duplicated(new_names)) >0 ){
new_names <- make.unique(new_names, sep = ".")
}
row.names(var_df) <- new_names

    if (reticulate::py_to_r(sp$issparse(ad$X))) {
      X <- Matrix::t(reticulate::py_to_r(sp$csc_matrix(ad$X)))
    } else {
      X <- t(reticulate::py_to_r(ad$X))
    }
    colnames(X) <- rownames(obs_df)
    rownames(X) <- rownames(var_df)

    # Check for layers['counts'] in adata.layers
    layers_counts <- NULL
    tryCatch({
      layer_keys <- reticulate::py_to_r(ad$layers$keys())
      if ("counts" %in% layer_keys) {
        message("Found 'counts' layer in adata.layers")
        if (reticulate::py_to_r(sp$issparse(ad$layers["counts"]))) {
          layers_counts <- Matrix::t(reticulate::py_to_r(sp$csc_matrix(ad$layers["counts"])))
        } else {
          layers_counts <- t(reticulate::py_to_r(ad$layers["counts"]))
        }
        colnames(layers_counts) <- rownames(obs_df)
        rownames(layers_counts) <- rownames(var_df)
      }
    }, error = function(e) {
      message(paste("No layers found or error accessing layers:", e$message))
    })

    if (!is.null(reticulate::py_to_r(ad$raw))) {
      raw_var_df <- .var2feature_metadata(ad$raw$var)
      raw_X <- Matrix::t(reticulate::py_to_r(sp$csc_matrix(ad$raw$X)))
      colnames(raw_X) <- rownames(obs_df)
      rownames(raw_X) <- rownames(raw_var_df)
    } else {
      raw_var_df <- NULL
      raw_X <- NULL
    }

    # Simplified logic for h5ad loading:
    # x_to_counts = TRUE:  X -> counts (data = copy of counts)
    # x_to_counts = FALSE: X -> data only, counts from layers['counts'] or raw.X if available

    if (x_to_counts) {
      # User explicitly wants X as counts
      assays <- list(Seurat::CreateAssayObject(counts = X))
      message("X -> counts (x_to_counts=TRUE, data = copy of counts)")
    } else {
      # X -> data only, counts from other sources
      if (!is.null(layers_counts)) {
        # layers['counts'] -> counts, X -> data
        assays <- list(Seurat::CreateAssayObject(counts = layers_counts))
        assays[[1]] <- Seurat::SetAssayData(assays[[1]], layer = "data", new.data = X)
        message("X -> data; layers['counts'] -> counts")
      } else if (!is.null(raw_X)) {
        # raw.X -> counts, X -> data
        if (nrow(X) != nrow(raw_X)) {
          message("Raw layer has different genes than X, resizing to match")
          raw_X <- raw_X[rownames(raw_X) %in% rownames(X), , drop = F]
          X <- X[rownames(raw_X), , drop = F]
        }
        assays <- list(Seurat::CreateAssayObject(counts = raw_X))
        assays[[1]] <- Seurat::SetAssayData(assays[[1]], layer = "data", new.data = X)
        message("X -> data; raw.X -> counts")
      } else {
        # No counts source available, X -> data only (counts = NULL)
        assays <- list(Seurat::CreateAssayObject(data = X))
        message("X -> data only (no counts available)")
      }
    }
    names(assays) <- assay
    Seurat::Key(assays[[assay]]) <- paste0(tolower(assay), "_")

    if (main_layer == "scale.data" && !is.null(raw_X)) {
      assays[[assay]]@meta.features <- raw_var_df
    } else {
      assays[[assay]]@meta.features <- var_df
    }

    project_name <- sub("\\.h5ad$", "", basename(inFile))
    srt <- new("Seurat", assays = assays, project.name = project_name, version = packageVersion("Seurat"))
    Seurat::DefaultAssay(srt) <- assay
    Seurat::Idents(srt) <- project_name

    srt@meta.data <- obs_df
    embed_names <- unlist(reticulate::py_to_r(ad$obsm_keys()))
    if (length(embed_names) > 0) {
      embeddings <- sapply(embed_names, function(x) as.matrix(reticulate::py_to_r(ad$obsm[x])), simplify = FALSE, USE.NAMES = TRUE)
      names(embeddings) <- embed_names
      for (name in embed_names) {
        rownames(embeddings[[name]]) <- colnames(assays[[assay]])
      }

      dim.reducs <- vector(mode = "list", length = length(embeddings))
      for (i in seq(length(embeddings))) {
        name <- embed_names[i]
        embed <- embeddings[[name]]
        key <- switch(name,
          sub("_(.*)", "\\L\\1", sub("^X_", "", toupper(name)), perl = T),
          "X_pca" = "PC",
          "X_tsne" = "tSNE",
          "X_umap" = "UMAP"
        )
        colnames(embed) <- paste0(key, "_", seq(ncol(embed)))
        dim.reducs[[i]] <- Seurat::CreateDimReducObject(
          embeddings = embed,
          loadings = new("matrix"),
          assay = assay,
          stdev = numeric(0L),
          key = paste0(key, "_")
        )
      }
      names(dim.reducs) <- sub("X_", "", embed_names)

      for (name in names(dim.reducs)) {
        srt[[name]] <- dim.reducs[[name]]
      }
    }
  }

  srt@misc <- .uns2misc(ad, target_uns_keys = target_uns_keys)

  if (!is.null(outFile)) saveRDS(object = srt, file = outFile)

  srt
}
                           
.obs2metadata <- function(obs_pd, assay = "RNA") {
  obs_df <- .regularise_df(reticulate::py_to_r(obs_pd), drop_single_values = FALSE)
  attr(obs_df, "pandas.index") <- NULL
  colnames(obs_df) <- sub("n_counts", paste0("nCounts_", assay), colnames(obs_df))
  colnames(obs_df) <- sub("n_genes", paste0("nFeaturess_", assay), colnames(obs_df))
  return(obs_df)
}

.regularise_df <- function(df, drop_single_values = TRUE) {
  if (ncol(df) == 0) df[["name"]] <- rownames(df)
  if (drop_single_values) {
    k_singular <- sapply(df, function(x) length(unique(x)) == 1)
    if (sum(k_singular) > 0) {
      warning(
        paste("Dropping single category variables:"),
        paste(colnames(df)[k_singular], collapse = ", ")
      )
    }
    df <- df[, !k_singular, drop = F]
    if (ncol(df) == 0) df[["name"]] <- rownames(df)
  }
  return(df)
}

.var2feature_metadata <- function(var_pd) {
  var_df <- .regularise_df(reticulate::py_to_r(var_pd), drop_single_values = FALSE)
  attr(var_df, "pandas.index") <- NULL
  colnames(var_df) <- sub("dispersions_norm", "mvp.dispersion.scaled", colnames(var_df))
  colnames(var_df) <- sub("dispersions", "mvp.dispersion", colnames(var_df))
  colnames(var_df) <- sub("means", "mvp.mean", colnames(var_df))
  colnames(var_df) <- sub("highly_variable", "highly.variable", colnames(var_df))
  return(var_df)
}

.uns2misc <- function(ad, target_uns_keys = list()) {
  uns_keys <- intersect(target_uns_keys, reticulate::py_to_r(ad$uns_keys()))
  misc <- sapply(uns_keys, function(x) reticulate::py_to_r(ad$uns[x]), simplify = FALSE, USE.NAMES = TRUE)
  return(misc)
}


is_assay5 <- function(seurat_object, assay_name = NULL) {
  if (is.null(assay_name)) {
    assay_name <- DefaultAssay(seurat_object)
  }
  return(inherits(seurat_object[[assay_name]], "Assay5"))
}

# Helper: get meta.features (Assay5 uses @meta.data, Assay v4 uses @meta.features)
get_meta_features <- function(seurat_object, assay_name = NULL) {
  if (is.null(assay_name)) {
    assay_name <- DefaultAssay(seurat_object)
  }
  if (inherits(seurat_object[[assay_name]], "Assay5")) {
    return(seurat_object[[assay_name]]@meta.data)
  } else {
    return(seurat_object[[assay_name]]@meta.features)
  }
}

# Helper: set meta.features
set_meta_features <- function(seurat_object, meta_features_df, assay_name = NULL) {
  if (is.null(assay_name)) {
    assay_name <- DefaultAssay(seurat_object)
  }
  if (inherits(seurat_object[[assay_name]], "Assay5")) {
    seurat_object[[assay_name]]@meta.data <- meta_features_df
  } else {
    seurat_object[[assay_name]]@meta.features <- meta_features_df
  }
  return(seurat_object)
}


check_seurat_version <- function() {
  # Check if Seurat is installed
  if (!requireNamespace("Seurat", quietly = TRUE)) {
    return("Seurat is not installed")
  }

  # Get the version number
  version <- packageVersion("Seurat")

  # Convert version to character for easier parsing
  version_str <- as.character(version)

  # Check major version number
  major_version <- as.numeric(strsplit(version_str, "\\.")[[1]][1])

  if (major_version == 4) {
    return("Seurat v4")
  } else if (major_version == 5) {
    return("Seurat v5")
  } else {
    return(paste("Other Seurat version:", version_str))
  }
}


is_sparse_matrix_contains_decimal <- function(sparse_matrix, threshold = 0.1) {
  # 空の行列またはNULLの場合はFALSEを返す
  if (is.null(sparse_matrix) || (nrow(sparse_matrix) == 0 && ncol(sparse_matrix) == 0)) {
    return(FALSE)
  }
  # 非ゼロ要素のみを取得
  values <- sparse_matrix@x
  # 非ゼロ要素の総数を計算
  total_nonzero <- length(values)
  # 非ゼロ要素が0の場合はFALSEを返す
  if (total_nonzero == 0) {
    return(FALSE)
  }
  # 少数を含む要素の数を計算
  decimal_count <- sum(values != floor(values))
  # 少数を含む要素の割合を計算
  decimal_ratio <- decimal_count / total_nonzero
  # 割合がしきい値以上ならTRUE、そうでなければFALSE
  return(decimal_ratio >= threshold)
}