#!/bin/bash

#NOTE 1: RUN BEFORE installing the R libraries
#NOTE 2: RUN AS ROOT/SUDO


#Check if conda exists in path and if not, download and install miniconda3
CONDA_CHK=$(which conda)
if [[ $CONDA_CHK  == ""  ]]
then
	wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
	bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda_scanner/
	conda_path="/opt/conda_scanner/"
	rm Miniconda3-latest-Linux-x86_64.sh
else
	conda_path=$(which conda)
	conda_path=$(echo $conda_path | sed 's/condabin\/conda//g' | sed 's/bin\/conda//g')
fi


# CREATE A CONDA ENVIRONMENT FOR WHERE PYSCENIC, MACS2 AND PHATE WILL BE INSTALLED
$conda_path/bin/conda create -y -n pyscenic python=3.7
$conda_path/bin/conda activate pyscenic
$conda_path/bin/conda install -y -c anaconda cytoolz
$conda_path/envs/pyscenic/bin/pip install pyscenic
$conda_path/envs/pyscenic/bin/pip install macs2
$conda_path/envs/pyscenic/bin/pip install phate

#install some dependencies that are needed by a few of the R packages
#apt-get install -y gsl-bin libgsl23 libgslcblas0 libgsl-dev
#apt-get install -y hdf5-tools hdf5-helpers libhdf5-dev
#apt-get install -y gdal-bin libgdal-dev


