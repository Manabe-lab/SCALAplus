# Dimension reduction by PCA.
after_pca <- function(data){
  # Each row of data represents one cell and each column represents one gene.
  data_guiyi <- (data-min(data))/(max(data)-min(data))
  data_cov <- cov(data_guiyi)
  data_eigen <- eigen(data_cov)
  lambdanum <- min(which(abs(diff(data_eigen$values,2))<1e-3))
  data_pca <- data_guiyi%*%data_eigen$vectors[,1:lambdanum]
  return(data_pca)
}