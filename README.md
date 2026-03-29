<div align="center">
<img src="SCALAplus_logo.png" alt="SCALA+ Logo" width="300">
</div>

# SCALA+

A modified and extended version of [SCALA](https://github.com/PavlopoulosLab/SCALA) for multimodal analysis of single cell next generation sequencing data, with full Seurat v5 compatibility and significant additional analytical capabilities (modified since 2023).

## About

SCALA+ is based on the original SCALA developed by the teams at Biomedical Sciences Research Center "Alexander Fleming". We gratefully acknowledge the original SCALA developers for creating the foundation upon which SCALA+ is built.

For installation instructions and basic usage, please refer to the [original SCALA repository](https://github.com/PavlopoulosLab/SCALA).

### Citation

If you use SCALA+, please cite the original SCALA paper:

> Tzaferis C., Karatzas E., Baltoumas F.A., Pavlopoulos G.A., Kollias G., Konstantopoulos D. (2023) **SCALA: A web application for multimodal analysis of single cell next generation sequencing data.** *Computational and Structural Biotechnology Journal*; doi: [https://doi.org/10.1016/j.csbj.2023.10.032](https://doi.org/10.1016/j.csbj.2023.10.032)

----

## New Modules (not in original SCALA)

### Data Input
- **h5ad (AnnData) file import** with flexible slot mapping (X, raw.X, layers)
- **CellBender h5 file import** with ambient RNA removal quality metrics
- **qs/qs2 format support** for fast serialized Seurat objects
- **Visium spatial transcriptomics** data import
- **Multiple RDS/qs merge** for multi-sample integration
- **COMPASS data** loading support

### Preprocessing
- **Sample demultiplexing** — hashDemux, demuxmix, deMULTIplex2 with consensus calling, UpSet/alluvial plots, and diagnostic visualizations (completely new module)
- **DropletQC** — empty droplet detection via `emptyDrops` and damaged cell filtering (new QC tab)
- **CellBender remove-background** — ambient RNA contamination removal with `cell_probability` and `background_fraction` metadata
- **Velocyto** — spliced/unspliced count matrix generation from BAM files for RNA velocity analysis
- **scDblFinder** doublet detection (in addition to original DoubletFinder)

### Analysis
- **DEG analysis** — dedicated differential expression module (separate from marker identification)
- **Gene Set Score** — gene set scoring with UCell and **GSDensity** pathway analysis
- **Pseudobulk analysis** — aggregation and differential expression at pseudobulk level
- **Spatial transcriptomics analysis** — Visium spatial feature visualization and analysis
- **BANKSY** — spatially-aware clustering

### Data Integration / Batch Correction
- **Harmony** integration
- **Scanorama** integration
- **FastMNN** integration
- **SCTransform** normalization
- Seurat v5 `IntegrateLayers` API (CCA, RPCA, Joint PCA)
- Leiden clustering (replacing Louvain, `algorithm=4`)

----

## Enhancements to Existing SCALA Modules

### Seurat v5 Compatibility
- Full Seurat v5 (Assay5) support across all data loading, gene name handling, and slot access
- Assay version (v4/v5) selection in data input panels
- Patched `Rmagic::magic.Seurat` for SeuratObject v5

### Visualization
- **UMAP cluster highlight** with configurable fill/border opacity and draw-order control
- **"Use UMAP colors"** option for VlnPlot, Stacked VlnPlot, and Heatmaps
- **Polychrome** alphabet palette (26 distinct colors) and **Palo** color optimization

### Data Loading
- Cellranger annotate results loader in metadata tab
- Auto-merge for multiple prefixed 10X files in folder upload
- Ensembl-to-symbol gene name conversion with Assay5 compatibility
- Gene name duplicate aggregation

### Other
- NicheNet database updated from v1 to v2
- Cairo PDF output for alpha transparency support

----

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
