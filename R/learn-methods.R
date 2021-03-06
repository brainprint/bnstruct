#' @rdname learn.network
#' @aliases learn.network,BN
setMethod("learn.network",
          c("BN"),
          function(x, y = NULL, algo = "mmhc", scoring.func = "BDeu", initial.network = NULL, 
                   alpha = 0.05, ess = 1, bootstrap = FALSE,
                   layering = c(), max.fanin.layers = NULL, max.fanin = num.variables(dataset),
                   layer.struct = NULL, cont.nodes = c(), use.imputed.data = FALSE, use.cpc = TRUE, ...)
          {
            if (is.null(y) || class(y) != "BNDataset")
              stop("A BNDataset must be provided in order to learn a network from it. ",
                   "Please take a look at the documentation of the method: > ?learn.network")
            
            bn <- x
            dataset <- y
            if (num.time.steps(dataset) > 1) {
              bn <- learn.dynamic.network(bn, dataset, num.time.steps(dataset), algo, scoring.func,
                                          initial.network, alpha, ess,
                                          bootstrap, layering, max.fanin.layers, max.fanin,
                                          layer.struct, cont.nodes, use.imputed.data, use.cpc, ...)
            } else {
              bn <- learn.structure(bn, dataset, algo, scoring.func, initial.network, alpha, ess,
                                    bootstrap, layering, max.fanin.layers, max.fanin,
                                    layer.struct, cont.nodes, use.imputed.data, use.cpc, ...)
              
              if (!bootstrap && algo != "mmpc")
                bn <- learn.params(bn, dataset, ess, use.imputed.data)
            }
            
            return(bn)
          })
#' @rdname learn.network
#' @aliases learn.network,BNDataset
setMethod("learn.network",
          c("BNDataset"),
          function(x, algo = "mmhc", scoring.func = "BDeu", initial.network = NULL,
                   alpha = 0.05, ess = 1, bootstrap = FALSE,
                   layering = c(), max.fanin.layers = NULL, max.fanin = num.variables(dataset),
                   layer.struct = NULL, cont.nodes = c(), use.imputed.data = FALSE, use.cpc = TRUE, ...)
          {
            dataset <- x
            bn <- BN(dataset)
            if (num.time.steps(dataset) > 1) {
              bn <- learn.dynamic.network(bn, dataset, num.time.steps(dataset), algo, scoring.func,
                                          initial.network, alpha, ess,
                                          bootstrap, layering, max.fanin.layers, max.fanin,
                                          layer.struct, cont.nodes, use.imputed.data, use.cpc, ...)
            } else {
              bn <- learn.structure(bn, dataset, algo, scoring.func, initial.network, alpha, ess,
                                    bootstrap, layering, max.fanin.layers, max.fanin,
                                    layer.struct, cont.nodes, use.imputed.data, use.cpc, ...)
              
              if (!bootstrap && algo != "mmpc")
                bn <- learn.params(bn, dataset, ess, use.imputed.data)
            }
            
            return(bn)
          })

#' @rdname learn.dynamic.network
#' @aliases learn.dynamic.network,BN
setMethod("learn.dynamic.network",
          c("BN"),
          function(x, y = NULL, num.time.steps = num.time.steps(y), algo = "mmhc", scoring.func = "BDeu", initial.network = NULL, 
                   alpha = 0.05, ess = 1, bootstrap = FALSE,
                   layering = c(), max.fanin.layers = NULL, max.fanin = num.variables(y),
                   layer.struct = NULL, cont.nodes = c(), use.imputed.data = FALSE, use.cpc = TRUE, ...)
          {
            if (is.null(y) || class(y) != "BNDataset")
              stop("A BNDataset must be provided in order to learn a network from it. ",
                   "Please take a look at the documentation of the method: > ?learn.dynamic.network")
            
            bn <- x
            dataset <- y
            
            if (num.variables(dataset) %% num.time.steps != 0) {
              stop("There should be the same number of variables in each time step.")
            }
            
            nv <- num.variables(dataset) / num.time.steps
            
            nl <- layering
            mfl <- max.fanin.layers
            ls <- layer.struct
            
            if (is.null(layering)) {
              nl <- rep(1,nv)
            } else {
              if (length(layering) != nv && length(layering) != num.variables(x)) {
                stop("If a layering is provided, it should be either as long as the number of variables in each time step, or as the total number of variables in all the time steps.")
              }
            }
            
            num.layers <- length(unique(nl))
            
            copynl <- nl
            while (length(nl) < num.variables(x)) {
              nl <- c(nl, copynl+max(nl))
            }
            
            layering <- nl
            
            if (is.null(layer.struct)) {
              ls <- matrix(0, num.layers * num.time.steps, num.layers * num.time.steps)
              ls[upper.tri(ls, diag=TRUE)] <- 1
              layer.struct <- ls
            } else {
              tmp.ls <- NULL
              for (i in 1:num.time.steps) {
                if (i == 1)
                  nr <- ls
                else
                  nr <- matrix(0, num.layers, num.layers)
                for (j in 2:num.time.steps) {
                  if (j < i) {
                    nr <- cbind(nr, matrix(0, num.layers, num.layers))
                  } else if (i == j) {
                    nr <- cbind(nr, ls)
                  } else {
                    nr <- cbind(nr, matrix(1, num.layers, num.layers))
                  }
                }
                tmp.ls <- rbind(tmp.ls, nr)
              }
              layer.struct <- tmp.ls
            }
            
            
            bn <- learn.structure(bn, dataset, algo, scoring.func, initial.network, alpha, ess,
                                  bootstrap, layering, max.fanin.layers, max.fanin,
                                  layer.struct, cont.nodes, use.imputed.data, use.cpc, ...)
            
            if (!bootstrap && algo != "mmpc")
              bn <- learn.params(bn, dataset, ess, use.imputed.data)

            return(bn)
          })
#' @rdname learn.dynamic.network
#' @aliases learn.dynamic.network,BNDataset
setMethod("learn.dynamic.network",
          c("BNDataset"),
          function(x, num.time.steps = num.time.steps(x), algo = "mmhc", scoring.func = "BDeu", initial.network = NULL,
                   alpha = 0.05, ess = 1, bootstrap = FALSE,
                   layering = c(), max.fanin.layers = NULL, max.fanin = num.variables(x),
                   layer.struct = NULL, cont.nodes = c(), use.imputed.data = FALSE, use.cpc = TRUE, ...) {
            
            dataset <- x
            bn <- BN(dataset)
            
            if (num.variables(x) %% num.time.steps != 0) {
              stop("There should be the same number of variables in each time step.")
            }
            
            nv <- num.variables(x) / num.time.steps
            
            nl <- layering
            mfl <- max.fanin.layers
            ls <- layer.struct
            
            if (is.null(layering)) {
              nl <- rep(1,nv)
            } else {
              if (length(layering) != nv && length(layering) != num.variables(x)) {
                stop("If a layering is provided, it should be either as long as the number of variables in each time step, or as the total number of variables in all the time steps.")
              }
            }
            
            num.layers <- length(unique(nl))
            
            copynl <- nl
            while (length(nl) < num.variables(x)) {
              nl <- c(nl, copynl+max(nl))
            }
            
            layering <- nl
            
            if (is.null(layer.struct)) {
              ls <- matrix(0, num.layers * num.time.steps, num.layers * num.time.steps)
              ls[upper.tri(ls, diag=TRUE)] <- 1
              layer.struct <- ls
            } else {
              tmp.ls <- NULL
              for (i in 1:num.time.steps) {
                if (i == 1)
                  nr <- ls
                else
                  nr <- matrix(0, num.layers, num.layers)
                for (j in 2:num.time.steps) {
                  if (j < i) {
                    nr <- cbind(nr, matrix(0, num.layers, num.layers))
                  } else if (i == j) {
                    nr <- cbind(nr, ls)
                  } else {
                    nr <- cbind(nr, matrix(1, num.layers, num.layers))
                  }
                }
                tmp.ls <- rbind(tmp.ls, nr)
              }
              layer.struct <- tmp.ls
            }
            
            bn <- learn.structure(bn, dataset, algo, scoring.func, initial.network, alpha, ess,
                                  bootstrap, layering, max.fanin.layers, max.fanin,
                                  layer.struct, cont.nodes, use.imputed.data, use.cpc, ...)
            
            if (!bootstrap && algo != "mmpc")
              bn <- learn.params(bn, dataset, ess, use.imputed.data)
            
            return(bn)
          })

#' @rdname learn.params
#' @aliases learn.params,BN,BNDataset
#' @importFrom stats complete.cases median pchisq quantile runif
setMethod("learn.params",
          c("BN", "BNDataset"),
          function(bn, dataset, ess = 1, use.imputed.data = FALSE)
          {
            # Learn the CPTs of each node, given data, DAG, node sizes and equivalent sample size
            # CPTs have the parents on dimensions 1:(n-1) and the child on the last dimension,
            # so that the sum over the last dimension is always 1
            
            if (struct.algo(bn) == "mmpc") {
              bnstruct.start.log("no parameter learning possible for network learnt using the MMPC algorithm")
              return(bn)
            }

            bnstruct.start.log("learning network parameters ... ")
            
            # just to play safe
            if (use.imputed.data)
              data <- as.matrix(imputed.data(dataset))
            else
              data <- as.matrix(raw.data(dataset))
            

            # storage.mode(data) <- "integer"
            
            node.sizes <- node.sizes(bn)
            dag        <- dag(bn)
            n.nodes    <- num.nodes(bn)
            variables  <- variables(bn)
            
#             storage.mode(dag) <- "integer"
            storage.mode(node.sizes) <- "integer"

            # quantize data of continuous nodes 
            cont.nodes <- which(!discreteness(bn))
            levels <- rep( 0, n.nodes )
            levels[cont.nodes] <- node.sizes[cont.nodes]
            
            # data <- quantize.with.na.matrix( data, levels )
            data <- quantize.matrix( data, levels )

            #n.nodes <- dataset@num.items #dim(data)[2]
            cpts <- list("list",n.nodes)
            var.names <- c(unlist(variables))  # colnames(data)
            d.names <- mapply(function(name,size)(1:size),var.names,node.sizes)
            # esimate a cpt for each family from data
            for ( i in 1:n.nodes )
            {
              family <- c( which(dag[,i]!=0), i )
              counts <- .Call( "compute_counts_nas", data[,family], node.sizes[family], 
                               PACKAGE = "bnstruct" )
              counts <- array(c(counts), c(node.sizes[family]))
              cpts[[i]] <- counts.to.probs( counts + ess / prod(dim(counts)) )
              dms <- NULL
              dns <- NULL
              for (j in 1:length(family))
              {
                dms[[j]] <- as.list(c(1:node.sizes[family[j]]))
                dns[[j]] <- c(var.names[family[j]])
              }
              
              dimnames(cpts[[i]])          <- dms
              names( dimnames(cpts[[i]]) ) <- dns
                
            }
            names(cpts) <- var.names
            
            #return( cpts )
            
            cpts(bn) <- cpts

            bnstruct.end.log("parameter learning done.")

            return(bn)
          }
)

#' @rdname learn.structure
#' @aliases learn.structure,BN,BNDataset
setMethod("learn.structure",
          c("BN", "BNDataset"),
          function(bn, dataset, algo = "mmhc", scoring.func = "BDeu", initial.network = NULL,
                   alpha = 0.05, ess = 1, bootstrap = FALSE,
                   layering = c(), max.fanin.layers = NULL, max.fanin = num.variables(dataset),
                   layer.struct = NULL, cont.nodes = c(), use.imputed.data = FALSE, use.cpc = TRUE, ...)
          {
            
            # setup
            num.nodes(bn)  <- num.variables(dataset)
            node.sizes(bn) <- node.sizes(dataset)
            variables(bn)  <- variables(dataset)
            validObject(bn)
            
            node.sizes <- node.sizes(bn)
            num.nodes  <- num.nodes(bn)
            
            if (length(cont.nodes) == 0)
              cont.nodes <- setdiff(1:num.nodes,which(discreteness(dataset)))
            
            # get data
            if (bootstrap)
            {
              if (!has.boots(dataset))
                stop("Bootstrap samples not available. Please generate samples before learning with bootstrap.\nSee > ?bootstrap for help.")
              
              if (use.imputed.data && !has.imputed.boots(dataset))
                stop("Imputed samples not available. Please generate imputed samples before learning.\nSee > ?bootstrap for help.")

              num.boots <- num.boots(dataset)
            }
            else
            {
              # not bootstrap (default)
              if (use.imputed.data && has.imputed.data(dataset))
                data   <- imputed.data(dataset)
              else if (use.imputed.data && !has.imputed.data(dataset))
                stop("Imputed data not available. Please impute data before learning.\nSee > ?impute for help.")
              else
                data <- raw.data(dataset)
            }
            
            # get scoring function:
            # 0 for BDeu
            # 1 for AIC
            # 2 for BIC
            # to ease things on the C side
            scoring.func <- match(tolower(scoring.func), c("bdeu", "aic", "bic"))
            if (is.na(scoring.func))
            {
              bnstruct.log("scoring function not recognized, using BDeu")
              scoring.func <- 0
            }
            else {
              scoring.func <- scoring.func - 1
            }
            scoring.func(bn) <- c("BDeu", "AIC", "BIC")[scoring.func + 1]
            
            algo <- tolower(algo)
            if (!algo %in% c("sm", "mmhc", "sem", "mmpc", "hc")) {
              bnstruct.log("structure learning algorithm not recognized, using MMHC")
              bnstruct.log("(available options are: SM, MMHC, MMPC, HC, SEM)")
              algo <- "mmhc"
            }
            
            # get initial.network
            if (!is.null(initial.network))
            {
              if (class(initial.network) == "BN")
                init.net <- initial.network
              else if (class(initial.network) == "matrix")
              {
                init.net      <- BN(dataset)
                dag(init.net) <- initial.network
                init.net      <- learn.params(init.net, dataset)
              }
              else if (class(initial.network) == "character" &&
                       tolower(initial.network) == "random.chain")
                init.net <- sample.chain(dataset)
              else # string != "random.chain"
                init.net <- NULL
              if (!is.null(init.net))
                validObject(init.net)
            }
            else
              init.net <- NULL
            
            # other params
            other.args <- list(...)
            
            if ("tabu.tenure" %in% names(other.args))
              tabu.tenure <- as.numeric(other.args$tabu.tenure)
            else
              tabu.tenure <- 100
            if ("seed" %in% names(other.args))
              set.seed(as.numeric(other.args$seed))
            else
              set.seed(0)
            
            #if ("struct.threshold" %in% names(other.args))
              #struct.threshold <- as.numeric(other.args$struct.threshold)
            #else
              #struct.threshold <- 10

            # switch on algorithm
            if (algo == "sm")
            {
              bnstruct.start.log("learning the structure using SM ...")
              if (bootstrap)
              {
                finalPDAG <- matrix(0,num.nodes,num.nodes)
                for( i in seq_len(num.boots(dataset)) )
                {
                  data <- boot(dataset, i, use.imputed.data = use.imputed.data)
                  
                  dag <- sm(data, node.sizes, scoring.func, cont.nodes, max.fanin, layering,
                            max.fanin.layers, ess)
                  
                  finalPDAG <- finalPDAG + dag.to.cpdag( dag, layering )
                }
                wpdag(bn) <- finalPDAG
              }
              else
              {     
                dag(bn)  <- sm(data, node.sizes, scoring.func, cont.nodes,
                               max.fanin, layering, max.fanin.layers, ess)
              }
              bnstruct.end.log("learning using SM completed.")
            } # end if algo == sm
            
            if (algo == "sem")
            {
              bnstruct.start.log("learning the structure using SEM ...")

              bn <- sem(bn, dataset,
                        scoring.func = c("BDeu", "AIC", "BIC")[scoring.func + 1],
                        initial.network = init.net,
                        alpha = alpha, ess = ess, bootstrap = bootstrap,
                        layering = layering, max.fanin.layers = max.fanin.layers,
                        max.fanin = max.fanin, cont.nodes = cont.nodes,
                        use.imputed.data = use.imputed.data,
                        use.cpc = use.cpc, ...)
              
              bnstruct.end.log("learning using SEM completed.")
            } # end if (algo == sem)
            
            # could be done just by changing some parameters and leaving it to
            # mmhc, but as we have the log messages I prefer to avoid confusion
            #
            # I assume the following settings, otherwise it makes little sense, so I ignore them:
            # - use.cpc = TRUE
            # - init.net = NULL
            #
            # Doubt: I save the non-dag in wpdag(bn), is this ok?
            # Saving in dag() gould cause problems in case of loops.
            # Shall we assume the users know what they're doing?
            if (algo == "mmpc")
            {
              bnstruct.start.log("learning the structure using MMPC ...")
              
              if (bootstrap)
              {
                finalPDAG <- matrix(0,num.nodes,num.nodes)
                for( i in seq_len(num.boots(dataset)) )
                {
                  data <- boot(dataset, i, use.imputed.data=use.imputed.data)
                  cpc <- mmpc( data, node.sizes, cont.nodes, alpha, layering, layer.struct )
                  finalPDAG <- finalPDAG + cpc
                }
                wpdag(bn) <- finalPDAG
              }
              else
              {
                cpc <- mmpc( data, node.sizes, cont.nodes, alpha, layering, layer.struct )
                wpdag(bn) <- cpc
              }
              bnstruct.end.log("learning using MMPC completed.")
            } # end if algo == mmpc
            
            # same here.
            # use.cpc = FALSE
            if (algo == "hc")
            {
              bnstruct.start.log("learning the structure using HC ...")
              
              if (!is.null(init.net))
                in.dag <- dag(init.net)
              else
                in.dag <- NULL
              
              if (bootstrap)
              {
                finalPDAG <- matrix(0,num.nodes,num.nodes)
                for( i in seq_len(num.boots(dataset)) )
                {
                  data <- boot(dataset, i, use.imputed.data=use.imputed.data)
                  cpc <- matrix(rep(1, num.nodes*num.nodes), nrow = num.nodes, ncol = num.nodes)
                  dag <- hc( data, node.sizes, scoring.func, cpc, cont.nodes, ess = ess,
                             tabu.tenure = tabu.tenure, init.net = in.dag)
                  finalPDAG <- finalPDAG + dag.to.cpdag( dag, layering )
                }
                wpdag(bn) <- finalPDAG
              }
              else
              {
                cpc <- matrix(rep(1, num.nodes*num.nodes), nrow = num.nodes, ncol = num.nodes)
                dag(bn) <- hc( data, node.sizes, scoring.func, cpc, cont.nodes, ess = ess,
                               tabu.tenure = tabu.tenure, init.net = in.dag )
              }
              bnstruct.end.log("learning using HC completed.")
            } # end if algo == hc
            
            if (algo == "mmhc") # default
            {
              bnstruct.start.log("learning the structure using MMHC ...")
              
              if (!is.null(init.net))
                in.dag <- dag(init.net)
              else
                in.dag <- NULL
                            
              if (bootstrap)
              {
                finalPDAG <- matrix(0,num.nodes,num.nodes)
                for( i in seq_len(num.boots(dataset)) )
                {
                  data <- boot(dataset, i, use.imputed.data=use.imputed.data)
                  
                  if (use.cpc){
                    cpc <- mmpc( data, node.sizes, cont.nodes, alpha, layering, layer.struct )
                  }
                  else
                  {
                    cpc <- matrix(rep(1, num.nodes*num.nodes), nrow = num.nodes, ncol = num.nodes)
                  }
                  dag <- hc( data, node.sizes, scoring.func, cpc, cont.nodes, ess = ess,
                             tabu.tenure = tabu.tenure, init.net = in.dag)
                  finalPDAG <- finalPDAG + dag.to.cpdag( dag, layering )
                }
                wpdag(bn) <- finalPDAG
              }
              else
              {
                if (use.cpc)
                  cpc <- mmpc( data, node.sizes, cont.nodes, alpha, layering, layer.struct )
                else
                  cpc <- matrix(rep(1, num.nodes*num.nodes), nrow = num.nodes, ncol = num.nodes)
                dag(bn) <- hc( data, node.sizes, scoring.func, cpc, cont.nodes, ess = ess,
                               tabu.tenure = tabu.tenure, init.net = in.dag )
              }
              bnstruct.end.log("learning using MMHC completed.")
            } # end if algo == mmhc
            
            struct.algo(bn) <- algo
            
            return(bn)
          })

counts.to.probs <- function( counts )
{
  d <- dim(counts)
  if( length(d) == 1 )
    return( counts / sum(counts) )
  else
  {
    # last dimension on the columns, everything else on the rows
    tmp.d <- c( prod(d[1:(length(d)-1)]), d[length(d)] )
    dim(counts) <- tmp.d
    # normalization
    nor <- rowSums( counts )
    nor <- nor + (nor == 0) # for the next division
    counts <- counts / array(nor,tmp.d)
    dim(counts) <- d
    return( counts )
  }
}
