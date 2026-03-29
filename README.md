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

> Tzaferis C., Karatzas E., Baltoumas F.A., Pavlopoulos G.A., Kollias G., Konstantopoulos D. (2022) **SCALA: A web application for multimodal analysis of single cell next generation sequencing data.** *bioRxiv 2022.11.24.517826*; doi: [https://doi.org/10.1101/2022.11.24.517826](https://doi.org/10.1101/2022.11.24.517826)

----

## Changes from Original SCALA

### Seurat v5 Compatibility
- Full Seurat v5 (Assay5) support across data loading, gene name handling, and slot access
- Migrated Seurat integration from v3 to v5 `IntegrateLayers` API
- Fixed `JoinLayers` for matrix/10X loading and Ensembl conversion
- Assay version (v4/v5) selection in data input panels
- Patched `Rmagic::magic.Seurat` for SeuratObject v5 (`slot` to `layer`)

### New Analysis Features
- **GSDensity** pathway analysis in Gene Set Score tab (with Seurat v5 compatibility fixes)
- **DropletQC** tab for empty droplet and damaged cell detection (`emptyDrops`)
- **CellBender** integration with `cell_probability` and `background_fraction` in metadata
- **UMAP cluster highlight** with configurable fill/border opacity and draw-order control
- **"Use UMAP colors"** option for VlnPlot, Stacked VlnPlot, and Heatmaps
- **Polychrome** alphabet palette (26 distinct colors) and **Palo** color optimization

### Demultiplexing Improvements
- Default changed to primary candidates (demuxmix + hashDemux)
- Added deMULTIplex2 diagnostic plots (posterior distribution + UMAP)
- Added hashDemux clustering visualization plots (UMAP, Heatmap, Confidence)
- Improved UpSet plot: all intersections shown, Non-Singlet handling fixed
- HTO filter fixes (`ncol()` instead of `length()`, threshold 0.1)

### Batch Correction
- Switched clustering from Louvain to Leiden (`algorithm=4`)
- Unified cluster naming across all batch correction methods
- Fixed reduction overwrite bug in Harmony/Scanorama and Seurat integration
- Fixed FastMNN reductions being overwritten by saved reductions
- Fixed GenomicRanges namespace conflict in FastMNN

### Data Loading
- COMPASS data loading support for h5ad upload
- Cellranger annotate results loader in Manipulate metadata tab
- Auto-merge for multiple prefixed 10X files in folder upload
- Fixed Ensembl-to-symbol conversion preserving Assay5 class with `percent.mt` recalculation
- Fixed h5ad gene name column warning (character/factor columns only)

----

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
