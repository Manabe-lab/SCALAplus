#Obtain the trajectory result of DensityPath####
densitypathimage<-function(XX,pdfname){
  
  # Input:
  # XX: the cordination of cells in 2d space, and each row represents
  # a cell with each column meaning one gene.
  #   pdfname: the name of the results pdf.
  # Output:
  #   four figures in one saved in the pdf the user specified.
  
  XX <- (XX-min(XX))/(max(XX)-min(XX))
  k <- round(nrow(XX)/100)
  n <- dim(XX)[1]
  d <- dim(XX)[2]
  distMat <- XX
  adjMat <- diag(n)
  knnInfo <- FNN::get.knn(XX, k = k, algorithm = "kd_tree")
  for (i in seq_len(n)) {
    adjMat[i, knnInfo[["nn.index"]][i, ]] <- 1
  }
  
  # different methods to calculate the multi-dimensional bandwidth, and it seems Hpi() function
  # is suits the level set clustering method best.
  # h <- Hns(XX)
  h <- Hpi(XX)
  # h <- Hlscv(XX)
  
  #the kde() function computes a binned kernel density estimator, which is an approximation based on Fast Fourier transforms to improve the calculation speed. 
  #    Some times in these approximate calculations, there can some approximation errors. 
  #    If you want to improve the computation speed, you can use:
  #hat.f <- ks::kde(XX, H = h, eval.points = XX)$estimate
  #    If you prefer exact estimation, you can use:
  hat.f <- ks::kde(XX, H = h, eval.points = XX)$estimate
  ord.hat.f <- order(hat.f)
  G <- igraph::graph.adjacency(adjMat, mode = "undirected")
  Lambda <- hat.f[ord.hat.f]
  Nlambda <- min(n, 150)
  Lambda <- seq(min(Lambda), max(Lambda), length = Nlambda)
  exclude <- numeric()
  CLUSTERS <- list()
  for (j in seq_len(Nlambda)) {
    OldExcluded <- exclude
    lambda <- Lambda[j]
    present <- which(hat.f >= lambda)
    exclude <- setdiff(seq_len(n), present)
    NewExcluded <- setdiff(exclude, OldExcluded)
    G[NewExcluded, present] <- FALSE
    clust <- igraph::clusters(G)
    CLUSTERS[[j]] <- list(no = clust[["no"]], mem = clust[["membership"]], 
                          present = present, exclude = exclude)
  }
  id <- 0
  components <- list()
  generation <- numeric()
  for (j in seq_len(Nlambda)) {
    presentMembership <- unique(CLUSTERS[[j]][["mem"]][CLUSTERS[[j]][["present"]]])
    for (i in presentMembership) {
      id <- id + 1
      components[[id]] <- which(CLUSTERS[[j]][["mem"]] == i)
      generation[id] <- j
    }
  }
  father <- numeric()
  startF <- which(generation == 2)[1]
  for (i in startF:length(components)) {
    for (j in which(generation == (generation[i] - 1))) {
      if (setequal(intersect(components[[i]], components[[j]]), 
                   components[[i]])) {
        father[i] <- j
        break
      }
    }
  }
  father[is.na(father)] <- 0
  bb <- 0
  branch <- numeric()
  base <- numeric()
  top <- numeric()
  bottom <- numeric()
  compBranch <- list()
  silo <- list()
  rank <- numeric()
  parent <- numeric()
  children <- list()
  if (sum(generation == 1) > 1) {
    bb <- bb + 1
    silo[[bb]] <- c(0, 1)
    base[bb] <- 0.5
    compBranch[[bb]] <- seq_len(n)
    rank[bb] <- 1
    parent[bb] <- 0
    top[bb] <- 0
    bottom[bb] <- 0
  }
  for (i in seq(along = father)) {
    if (sum(generation == 1) > 1 & generation[i] == 1) {
      Bros <- which(generation == generation[i])
      bb <- bb + 1
      branch[i] <- bb
      rank[bb] <- sum(generation[seq_len(i)] == generation[i] & 
                        father[seq_len(i)] == father[i])
      silo[[bb]] <- TDA:::siloF(c(0, 1), length(Bros), rank[bb])
      base[bb] <- sum(silo[[bb]])/2
      top[bb] <- min(hat.f[components[[i]]])
      compBranch[[bb]] <- components[[i]]
      parent[bb] <- 1
      bottom[bb] <- 0
      if (length(children) < parent[bb]) {
        children[[parent[bb]]] <- bb
      }
      else {
        children[[parent[bb]]] <- c(children[[parent[bb]]], 
                                    bb)
      }
    }
    else if (sum(generation == 1) == 1 & generation[i] == 
             1) {
      bb <- bb + 1
      branch[i] <- bb
      silo[[bb]] <- c(0, 1)
      base[bb] <- 0.5
      top[bb] <- min(hat.f[components[[i]]])
      compBranch[[bb]] <- components[[i]]
      parent[bb] <- 0
      bottom[bb] <- 0
    }
    else {
      Bros <- which(generation == generation[i] & father == 
                      father[i])
      if (length(Bros) > 1) {
        bb <- bb + 1
        branch[i] <- bb
        parent[bb] <- branch[father[i]]
        rank[bb] <- sum(generation[seq_len(i)] == generation[i] & 
                          father[seq_len(i)] == father[i])
        silo[[bb]] <- TDA:::siloF(silo[[parent[bb]]], length(Bros), 
                                  rank[bb])
        base[bb] <- sum(silo[[bb]])/2
        top[bb] <- min(hat.f[components[[i]]])
        bottom[bb] <- top[parent[bb]]
        compBranch[[bb]] <- components[[i]]
        if (length(children) < parent[bb]) {
          children[[parent[bb]]] <- bb
        }
        else {
          children[[parent[bb]]] <- c(children[[parent[bb]]], 
                                      bb)
        }
      }
      if (length(Bros) == 1) {
        for (j in which(generation == (generation[i] - 
                                       1))) {
          if (setequal(intersect(components[[i]], components[[j]]), 
                       components[[i]])) 
            belongTo <- branch[j]
        }
        top[belongTo] <- min(hat.f[components[[i]]])
        branch[i] <- belongTo
      }
    }
  }
  
  
  out <- list(density = hat.f, DataPoints = compBranch, 
              n = n, id = seq_len(bb), children = children, parent = parent, 
              silo = silo, Xbase = base, lambdaBottom = bottom, 
              lambdaTop = top)
  
  TreeKDE <- out
  densityKDE<-TreeKDE$density
  idKDE<-setdiff(TreeKDE$id,TreeKDE$parent)
  numKDEleaves<-length(idKDE)
  l<-1
  KDEdensitypeaks<-matrix(1,numKDEleaves,2)
  for (i in idKDE){
    clusterkde<-TreeKDE$DataPoints[[i]]
    KDEdensitypeaks[l,]<-XX[clusterkde[which.max(densityKDE[clusterkde])],]
    l<-l+1
  }
  xmin <-min(XX)
  xmax<-max(XX)
  ymin<-min(XX)
  ymax<-max(XX)
  numcell<-nrow(XX)
  if (numcell<=10000)
  {
    numx<-101
    numy<-101
  }
  if(numcell>10000)
  {
    numx<-501
    numy<-501
  }
  Xlim <- c(xmin,xmax);  Ylim <- c(ymin, ymax);  
  by <- (xmax-xmin)/(numx-1)
  Xseq <- seq(Xlim[1], Xlim[2], by = by)
  Yseq <- seq(Ylim[2],Ylim[1], by = -by)
  Grid <- expand.grid(Xseq, Yseq)
  # calculate the density on the grid,and form a density surface
  # h <- Hns(XX)
  # h <- Hpi(XX)
  # h <- Hlscv(XX)
  
  
  #KDE <- ks::kde(XX, H = h, eval.points = Grid)$estimate
  #KDE[which(KDE<0)] <- min(KDE[which(KDE>0)])/10
  
  KDE <- ks::kde(XX, H = h, eval.points = Grid, binned = FALSE)$estimate
  
  r <- raster(nrows=numy, ncols=numx, xmn=xmin, xmx=xmax, ymn=ymin, ymx=ymax,crs="+proj=utm +units=m")
  r[] <- KDE
  T <- transition(r, function(x) mean(x), 8)
  T <- geoCorrection(T)
  C <-KDEdensitypeaks
  D <-KDEdensitypeaks
  # use the costDistance function in the gdistance package to calculate the geodesic distance between any two density peaks of 
  # the mesh surface
  dis<- costDistance(T, C, D)
  # calculate the minimun spanning tree by calling the spantree function in the vegan package using the geodesic distance matrix.
  spanningtree <- spantree(dis)
  # Output of the graph
  pdf(paste('Densitypath ',pdfname,'.pdf',sep = ''))
  par(mfrow = c(2,2))
  par(mai = c(0.7,0.4,0.4,0.4),oma=c(0.7,0.7,0.7,0.7))
  # 2-dimensional projection
  par(mgp=c(1,1,0))
  plot(XX, pch = 19, cex = 0.6, main =paste('2D projection ',sep = ''),xaxt="n",yaxt="n",
       xlab = 'EE1', ylab = 'EE2', bty = 'l', sub = '(a)', cex.sub = 1.3, font.sub = 2)
  # 3-dimensional density surface
  Xseq <- seq(Xlim[1], Xlim[2], by = by)
  Yseq <- seq(Ylim[1],Ylim[2], by = by)
  Grid <- expand.grid(Xseq, Yseq)
  #KDE <- ks::kde(XX, H = h, eval.points = Grid)$estimate
  #KDE[which(KDE<0)] <- min(KDE[which(KDE>0)])/10
  KDE <- ks::kde(XX, H = h, eval.points = Grid, binned = F)$estimate
  zh<- matrix(KDE,ncol=length(Yseq),nrow=length(Xseq))
  op <- par(bg = "white")
  res<-persp(Xseq, Yseq, zh, theta = 345, phi = 30,
             expand = 0.5, col = "white",d =1,
             r=90,
             ltheta = 90,
             shade = 0, 
             ticktype = "detailed",
             #xlab = "X", ylab = "Y", zlab = "Sinc( r )" ,
             box = TRUE,
             border=NA,main='Density landscape',
             axes=F,
             sub = '(b)',cex.sub = 1.3, font.sub = 2
  )
  # discrete density clusters
  par(mgp=c(1,1,0))
  plot(1:5,1:5,xlim=c(min(XX[,1]),max(XX[,1])),ylim=c(min(XX[,2]),max(XX[,2])),type = "n",main = "Density clusters",xlab="EEC1",ylab="EEC2",
       xaxt = 'n', yaxt = 'n', bty = 'l', sub = '(c)',cex.sub = 1.3, font.sub = 2)
  col <- intpalette(c('red','black','green','blue','pink','yellow','grey','orange','purple','cyan'),length(idKDE))
  c <- 1
  for (i in idKDE){
    points(matrix(XX[TreeKDE[["DataPoints"]][[i]], ], ncol = 2), col = col[c],pch = 19, cex = 1.5)
    c<-c+1
  }
  # density path
  p<-matrix(1,2,2)
  par(mgp=c(1,1,0))
  plot(r,xlim=c(min(XX[,1]),max(XX[,1])),ylim=c(min(XX[,2]),max(XX[,2])),main="Density path",xlab="EE1",ylab="EE2",
       xaxt = 'n', yaxt = 'n', sub = '(d)',cex.sub = 1.3, font.sub = 2)
  KDEidspantree<-spanningtree$kid
  numKDEedge<-numKDEleaves-1
  KDEspantree<-matrix(1,numKDEedge,2)
  KDEspantree[,1]<-as.matrix(2:numKDEleaves,numKDEleaves,1)
  KDEspantree[,2]<-t(KDEidspantree)
  for (i in 1:numKDEedge){
    p1<-KDEspantree[i,1]
    p2<-KDEspantree[i,2]
    p[1,]<-KDEdensitypeaks[p1,]
    p[2,]<-KDEdensitypeaks[p2,]
    p1top2 <- shortestPath(T, p[1,], p[2,], output="SpatialLines")
    lines(p1top2, col="black", lwd=1)
  }
  for (i in 1:numKDEleaves){
    points(KDEdensitypeaks[i,1],KDEdensitypeaks[i,2],pch = 19, cex = 1,col="black")
  }
  
  dev.off()
  
}
