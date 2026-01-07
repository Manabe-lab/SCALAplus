#Calculate the pseudotime and branch assignment of each cell.
dens_bran_pseu <- function(XX, originid){
  
  # Input:
  #   XX: the cordination of cells in 2d space, and each row represents
  #   a cell with each column meaning one gene.
  #   originid: the number of start cell which the user specified and it's 
  #   an optional vairiable. If originid is missing, pseudotime will not be
  #   calculated, but the branch assignment of each cell will still be 
  #   calculated. The originid doesn't influence the result of branch assignment
  #   therefore we set the first cell as the start point to calculate it.
  # Output:
  #   the list variable out_DP consists of:
  #     RCSs: a list variable, each element consists of the cell labels in representative cell states.
  #     pseudobran: a list variable and each element is the labels of the cells lying on the branch.
  #                 The branch is defined as a trajectory segment from the start RCS or one branching
  #                 RCS to the next branching point or the end RCS.
  #     MSTtree: an igraph variable saving the structure of trajectory. The RCSs are represented as nodes
  #              and branchs are represented with edges. The numbers labelling node means nothing, just a
  #              kind of symbol. The user can use plot() function to visualize the structure of it directly.
  #     start_cell: an annotion to show whether a start cell id is input or not.
  #     pseudotime: the normalized pseudotime of each cell. only included when originid is inputed.
  #     allpath: a list variable and each element is a list which contains the node and the position of the
  #              density peaks in one whole path. Only included when originid is inputed.
  #     pseudo_order: the pseudo-order of each whole path from the start cell to one of the end cell.
  #                   Only included when originid is inputed.
  
  XX <- (XX-min(XX))/(max(XX)-min(XX))
  k <- round(nrow(XX)/100)
  #clusterTree#####
  #calculate level set cluster based on TDA
  n <- dim(XX)[1]
  d <- dim(XX)[2]
  distMat <- XX
  adjMat <- diag(n)
  knnInfo <- FNN::get.knn(XX, k = k, algorithm = "kd_tree")
  for (i in seq_len(n)) {
    adjMat[i, knnInfo[["nn.index"]][i, ]] <- 1
  }
  h <- Hpi(XX)
  #hat.f <- ks::kde(XX, H = h, eval.points = XX)$estimate
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
  #density surface####
  #calculate the surface of density landscape
  TreeKDE <- out
  densityKDE<-TreeKDE$density
  idKDE<-setdiff(TreeKDE$id,TreeKDE$parent)
  levelcluster <- list()
  for(i in idKDE){
    tt <- TreeKDE$DataPoints[[i]]
    levelcluster <- c(levelcluster,list(tt))
  }
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
  #KDE <- ks::kde(XX, H = h, eval.points = Grid)$estimate
  #KDE[which(KDE<0)] <- min(KDE[which(KDE>0)])/10
  KDE <- ks::kde(XX, h = h, eval.points = Grid,binned = FALSE)$estimate
  r <- raster(nrows=numy, ncols=numx, xmn=xmin, xmx=xmax, ymn=ymin, ymx=ymax,crs="+proj=utm +units=m")
  r[] <- KDE
  T <- transition(r, function(x) mean(x), 8)
  T <- geoCorrection(T)
  C <-KDEdensitypeaks
  D <-KDEdensitypeaks
  # use the costDistance function in the gdistance package to calculate the geodesic distance between any two density peaks of 
  # the mesh surface
  dis<- costDistance(T, C, D)
  gp <- graph.adjacency(dis, mode = "undirected", weighted = TRUE)
  dp_mst <- minimum.spanning.tree(gp)
  # calculate the minimun spanning tree by calling the spantree function in the vegan package using the geodesic distance matrix.
  spanningtree <- spantree(dis)
  spantreeendid<-spanningtree$kid
  spantreeid<-matrix(0,numKDEleaves-1,2)
  spantreeid[,1]<-2:numKDEleaves
  spantreeid[,2]<-spantreeendid
  # MSTpath is a list variable and each element is a matrix which consists of the cordinations of points on the trajectory segmetn
  # and the start id and end id of the segment
  MSTpath<-list()
  for (i in 1:(numKDEleaves-1)) {
    
    id1<-spantreeid[i,1]
    id2<-spantreeid[i,2]
    startpoint<-KDEdensitypeaks[id1,]
    endpoint<-KDEdensitypeaks[id2,]
    shortestpath<-shortestPath(T,startpoint,endpoint,output='SpatialLines')
    pathpoints<-as.matrix(((((shortestpath@lines)[[1]])@Lines)[[1]])@coords)
    startid<-matrix(id1,nrow=(dim(pathpoints)[1])+2,ncol=1)
    endid<-matrix(id2,nrow=(dim(pathpoints)[1])+2,ncol=1)
    pathpoints<-rbind(startpoint,pathpoints,endpoint)
    newpath<-cbind(pathpoints,startid,endid)
    MSTpath<-c(MSTpath,list(newpath))
    
  }
  
  #globalpoints####
  for (i in 1:length(MSTpath)) {
    temp<-MSTpath[[i]]
    if (i==1)
      globalpoints<-temp
    else
      globalpoints<-rbind(globalpoints,temp)
  }
  #findpath####
  
  findpath<-function(node,prev_node,info){
    adj<-which(info[node,]!=0)
    kid<-setdiff(adj,prev_node)
    if(length(kid)==0)
      return(list(node))
    t<-list()
    l<-1
    for (i in kid) {
      path <- findpath(i, node, info)
      for (j in 1:length(path)) {
        t[[l]]<-c(node,path[[j]])
        l<-l+1
      }
    }
    return(t)
  }
  
  #waypoints####
  #Map each cell to the MST path
  if(missing(originid)){
    # calculate the root id and all path, allpath is a list variable and each 
    # element consist of the a series of ids of density peaks or level set clusters.
    # The number of each node is pointless, just a symbol to distinguish each node.
    originid <- 1
    disroot<-costDistance(T,XX[originid,],KDEdensitypeaks)
    rootid<-which.min(disroot)
    adj<-matrix(0,length(MSTpath)+1,length(MSTpath)+1)
    adj[spantreeid]<-1
    adj<-(adj+t(adj))
    allpath<-findpath(rootid,rootid,info = adj)
    
    # waypoints is the cordinations of points mapped onto the trajectory
    waypoints <- matrix(0,nrow = nrow(XX),ncol = 2)
    for (i in 1:nrow(XX)) {
      # print(i)
      point<-XX[i,]
      dis<-costDistance(T,point,globalpoints[,1:2])
      waypoints[i,]<-globalpoints[min(which(dis==min(dis))),1:2]
    }
    # calculate the branch segment of trajectory. Each branch segment is a partion from the start
    # point or one branching point to the next branching point or the terminal point.
    # bran_assign is an variable in list type and each element is a branch segment consisting of nodes of 
    # level set clusters
    bran_assign <- list()
    c <- 1
    fre <- as.integer(table(spantreeid))
    for(i in 1:length(allpath)){
      onepath <- allpath[[i]]
      ttfre <- fre[onepath]
      ttbreak <- which(ttfre>2)
      ttbreak <- c(1, ttbreak, length(onepath))
      for(i in 1:(length(ttbreak)-1)){
        bran_assign[[c]] <- onepath[ttbreak[i]:ttbreak[i+1]]
        c <- c+1
      }
    }
    bran_assign <- unique(bran_assign)
    
    # cellpath map is a matrix, where the first two elements of each row
    # represents the two ids on the trajectory segment where the cell lies.
    cellpathmap <- matrix(0, nrow = nrow(waypoints), ncol = 4)
    tt <- globalpoints[,1:2]
    for(i in seq_len(nrow(waypoints))){
      tt[,1] <- globalpoints[,1]-waypoints[i,1]
      tt[,2] <- globalpoints[,2]-waypoints[i,2]
      tt1 <- min(which(apply(abs(tt),1,sum)==0))
      tt2 <- which(globalpoints[,3]==globalpoints[tt1,3] & globalpoints[,4]==globalpoints[tt1,4])
      cellpathmap[i,1] <- globalpoints[tt1,3]
      cellpathmap[i,2] <- globalpoints[tt1,4]
      cellpathmap[i,3] <- tt1-min(tt2)+1
      cellpathmap[i,4] <- length(tt2)
    }
    
    # cell_on_bran is a list variable and each element is the label of the cells lying on the branch
    cell_on_bran <- list()
    for(i in 1:length(bran_assign)){
      tt <- bran_assign[[i]]
      ttcell <- integer()
      for(j in (1:length(tt)-1)){
        tt1 <- which(cellpathmap[,1]==tt[j]&cellpathmap[,2]==tt[j+1])
        tt2 <- which(cellpathmap[,2]==tt[j]&cellpathmap[,1]==tt[j+1])
        if(length(tt1)!=0)
          ttcell <- c(ttcell, tt1)
        else
          ttcell <- c(ttcell, tt2)
      }
      cell_on_bran <- c(cell_on_bran, list(ttcell))
    }
    
    out_DP <- list(RCSs = levelcluster, pseudobran = cell_on_bran,MSTtree = dp_mst, start_cell = 'No start cell')
    return(out_DP)
    
  }else{
    # calculate the root id and all path, allpath is a list variable and each 
    # element consist of the a series of ids of density peaks or level set clusters.
    # The number of each node is pointless, just a symbol to distinguish each node.
    disroot<-costDistance(T,XX[originid,],KDEdensitypeaks)
    rootid<-which.min(disroot)
    adj<-matrix(0,length(MSTpath)+1,length(MSTpath)+1)
    adj[spantreeid]<-1
    adj<-(adj+t(adj))
    allpath<-findpath(rootid,rootid,info = adj)
    
    # mapping the cells onto the reconstructed trajectory and calculate the pseudotime of 
    # each cell
    point<-XX[originid,]
    dis<-costDistance(T,point,globalpoints[,1:2])
    tt <- globalpoints[min(which(dis==min(dis))),1:2]
    originwaypoint <- matrix(tt, ncol = 2)
    # waypoints is the cordinations of points mapped onto the trajectory
    waypoints <- matrix(0,nrow = nrow(XX),ncol = 2)
    pseudotime <- double()
    for (i in 1:nrow(XX)) {
      point<-XX[i,]
      dis<-costDistance(T,point,globalpoints[,1:2])
      waypoints[i,]<-globalpoints[min(which(dis==min(dis))),1:2]
      pseudotime[i] <- costDistance(T,originwaypoint, waypoints[i,])
    }
    pseudotime <- pseudotime/max(pseudotime)
    
    # calculate the branch segment of trajectory. Each branch segment is a partion from the start
    # point or one branching point to the next branching point or the terminal point.
    # bran_assign is an variable in list type and each element is a branch segment consisting of nodes of 
    # level set clusters
    bran_assign <- list()
    c <- 1
    fre <- as.integer(table(spantreeid))
    for(i in 1:length(allpath)){
      onepath <- allpath[[i]]
      ttfre <- fre[onepath]
      ttbreak <- which(ttfre>2)
      ttbreak <- c(1, ttbreak, length(onepath))
      for(i in 1:(length(ttbreak)-1)){
        bran_assign[[c]] <- onepath[ttbreak[i]:ttbreak[i+1]]
        c <- c+1
      }
    }
    bran_assign <- unique(bran_assign)
    
    # cellpath map is a matrix, where the first two elements of each row
    # represents the two ids on the trajectory segment where the cell lies.
    cellpathmap <- matrix(0, nrow = nrow(waypoints), ncol = 4)
    tt <- globalpoints[,1:2]
    for(i in seq_len(nrow(waypoints))){
      tt[,1] <- globalpoints[,1]-waypoints[i,1]
      tt[,2] <- globalpoints[,2]-waypoints[i,2]
      tt1 <- min(which(apply(abs(tt),1,sum)==0))
      tt2 <- which(globalpoints[,3]==globalpoints[tt1,3] & globalpoints[,4]==globalpoints[tt1,4])
      cellpathmap[i,1] <- globalpoints[tt1,3]
      cellpathmap[i,2] <- globalpoints[tt1,4]
      cellpathmap[i,3] <- tt1-min(tt2)+1
      cellpathmap[i,4] <- length(tt2)
    }
    
    # cell_on_bran is a list variable and each element is the label of the cells lying on the branch
    cell_on_bran <- list()
    for(i in 1:length(bran_assign)){
      tt <- bran_assign[[i]]
      ttcell <- integer()
      for(j in (1:length(tt)-1)){
        tt1 <- which(cellpathmap[,1]==tt[j]&cellpathmap[,2]==tt[j+1])
        tt2 <- which(cellpathmap[,2]==tt[j]&cellpathmap[,1]==tt[j+1])
        if(length(tt1)!=0)
          ttcell <- c(ttcell, tt1)
        else
          ttcell <- c(ttcell, tt2)
      }
      cell_on_bran <- c(cell_on_bran, list(ttcell))
    }
    # ttallpath is a list variable and each element is a list which contains the
    # node and the position of the density peaks in this path
    ttallpath <- list()
    for(i in 1:length(allpath)){
      tt1 <- allpath[[i]]
      tt2 <- KDEdensitypeaks[allpath[[i]],]
      ttallpath[[i]] <- list(node = tt1, position = tt2)
    }
    # calculate the pseudo-order of each path from the start cell to one of the end cell.
    pseu_order <- list()
    path_name <- character()
    for(i in seq_along(allpath)){
      tt2 <- integer()
      for(j in seq_along(cell_on_bran)){
        tt1 <- is.na(all(match(bran_assign[[j]],allpath[[i]])))
        if(!tt1)
          tt2 <- c(tt2,cell_on_bran[[j]])
      }
      tt3 <- order(pseudotime[tt2],decreasing = FALSE)
      pseu_order[[i]] <- tt2[tt3]
      path_name[i] <- paste(allpath[[i]][1],allpath[[i]][length(allpath[[i]])],sep = '-')
      path_name[i] <- paste('node',path_name[i])
    }
    names(pseu_order) <- path_name
    out_DP <- list(RCSs = levelcluster, pseudotime = pseudotime, pseudobran = cell_on_bran, MSTtree = dp_mst, allpath = ttallpath,
                   start_cell = paste('cell',originid,sep=''),pseudo_order = pseu_order)
    return(out_DP)
  }
  
}