#!/bin/bash

mkdir -p nichenetr_helper_files
# NicheNet v2 databases (zenodo record 7074291)
# Human
wget -P nichenetr_helper_files https://zenodo.org/records/7074291/files/ligand_target_matrix_nsga2r_final.rds
wget -P nichenetr_helper_files https://zenodo.org/records/7074291/files/lr_network_human_21122021.rds
wget -P nichenetr_helper_files https://zenodo.org/records/7074291/files/weighted_networks_nsga2r_final.rds
wget -P nichenetr_helper_files https://zenodo.org/records/7074291/files/gr_network_human_21122021.rds
wget -P nichenetr_helper_files https://zenodo.org/records/7074291/files/ligand_tf_matrix_nsga2r_final.rds
wget -P nichenetr_helper_files https://zenodo.org/records/7074291/files/signaling_network_human_21122021.rds
# Mouse
wget -P nichenetr_helper_files https://zenodo.org/records/7074291/files/ligand_target_matrix_nsga2r_final_mouse.rds
wget -P nichenetr_helper_files https://zenodo.org/records/7074291/files/lr_network_mouse_21122021.rds
wget -P nichenetr_helper_files https://zenodo.org/records/7074291/files/weighted_networks_nsga2r_final_mouse.rds
wget -P nichenetr_helper_files https://zenodo.org/records/7074291/files/gr_network_mouse_21122021.rds
wget -P nichenetr_helper_files https://zenodo.org/records/7074291/files/ligand_tf_matrix_nsga2r_final_mouse.rds
wget -P nichenetr_helper_files https://zenodo.org/records/7074291/files/signaling_network_mouse_21122021.rds

mkdir -p scenic_helper_files

wget -P scenic_helper_files https://resources.aertslab.org/cistarget/databases/old/mus_musculus/mm9/refseq_r45/mc9nr/gene_based/mm9-500bp-upstream-10species.mc9nr.feather
wget -P scenic_helper_files https://resources.aertslab.org/cistarget/databases/old/mus_musculus/mm9/refseq_r45/mc9nr/gene_based/mm9-tss-centered-10kb-10species.mc9nr.feather
wget -P scenic_helper_files https://resources.aertslab.org/cistarget/databases/old/mus_musculus/mm10/refseq_r80/mc9nr/gene_based/mm10__refseq-r80__10kb_up_and_down_tss.mc9nr.feather
wget -P scenic_helper_files https://resources.aertslab.org/cistarget/databases/old/mus_musculus/mm10/refseq_r80/mc9nr/gene_based/mm10__refseq-r80__500bp_up_and_100bp_down_tss.mc9nr.feather
wget -P scenic_helper_files https://resources.aertslab.org/cistarget/databases/old/homo_sapiens/hg19/refseq_r45/mc9nr/gene_based/hg19-500bp-upstream-10species.mc9nr.feather
wget -P scenic_helper_files https://resources.aertslab.org/cistarget/databases/old/homo_sapiens/hg19/refseq_r45/mc9nr/gene_based/hg19-tss-centered-10kb-10species.mc9nr.feather
wget -P scenic_helper_files https://resources.aertslab.org/cistarget/databases/old/homo_sapiens/hg38/refseq_r80/mc9nr/gene_based/hg38__refseq-r80__500bp_up_and_100bp_down_tss.mc9nr.feather
wget -P scenic_helper_files https://resources.aertslab.org/cistarget/databases/old/homo_sapiens/hg38/refseq_r80/mc9nr/gene_based/hg38__refseq-r80__10kb_up_and_down_tss.mc9nr.feather
wget -P scenic_helper_files https://resources.aertslab.org/cistarget/motif2tf/motifs-v9-nr.mgi-m0.001-o0.0.tbl
wget -P scenic_helper_files https://resources.aertslab.org/cistarget/motif2tf/motifs-v9-nr.hgnc-m0.001-o0.0.tbl
wget -P scenic_helper_files https://raw.githubusercontent.com/aertslab/pySCENIC/master/resources/mm_mgi_tfs.txt
wget -P scenic_helper_files https://raw.githubusercontent.com/aertslab/pySCENIC/master/resources/hs_hgnc_curated_tfs.txt

