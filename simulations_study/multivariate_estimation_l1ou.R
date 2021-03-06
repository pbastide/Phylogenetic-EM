####################
## Parameters
####################
library(doParallel)
library(foreach)
library(l1ou)
library(phytools)
reqpckg <- c("l1ou", "phytools")

## Set number of parallel cores
Ncores <- 5

## Define date-stamp for file names
datestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
datestamp_day <- format(Sys.time(), "%Y-%m-%d")

## Load simulated data
datestamp_data <- "2016-08-09" # 
savedatafile = "../Results/Simulations_Multivariate/multivariate_simlist"
saveresultfile <- "../Results/Simulations_Multivariate/multivariate_estimations_l1ou"
load(paste0(savedatafile, "_", datestamp_data, ".RData"))

## These values should be erased by further allocations (generate_inference_files)
n.range <- nrep
inference.index <- 0

## Select data (according to the value of nrep)
nrep <- nrep

## Here n.range should be defined by generate_inference_files.R
simulations2keep <- sapply(simlist, function(x) { x$nrep %in% n.range }, simplify = TRUE)
simlist <- simlist[simulations2keep]
nbrSim <- length(simlist)

##########################
## Reorder trees postorder
##########################

trees_postorder <- lapply(trees, function(z) reorder.phylo(z, "postorder"))

######################
## Estimation Function
######################
estimations_l1ou <- function(X){
  Y_data <- t(X$Y_data)
  if (anyNA(Y_data))   return(list(sim = X, res = NULL))
  rownames(Y_data) <- trees[[paste0(X$ntaxa)]]$tip.label
  ## Do a pPCA
  Y_data_pPCA <- phyl.pca(trees_postorder[[paste0(X$ntaxa)]], Y_data)
  Y_data_pPCA <- Y_data_pPCA$S
  ## l1ou fit
  time_l1ou <- system.time(
  res <- estimate_shift_configuration(tree = trees_postorder[[paste0(X$ntaxa)]],
                                      Y = Y_data_pPCA,
                                      # max.nShifts = floor(length(trees_postorder[[paste0(X$ntaxa)]]$tip.label)/2),
                                      criterion = "pBIC",
                                      root.model = "OUrandomRoot",
                                      candid.edges = NA,
                                      quietly = TRUE,
                                      alpha.starting.value = NA,
                                      # alpha.upper = alpha_upper_bound(tree),
                                      alpha.lower = NA,
                                      rescale = TRUE,
                                      edge.length.threshold = .Machine$double.eps,
                                      grp.delta = 1/16,
                                      grp.seq.ub = 5,
                                      l1ou.options = NA)
  )
  # Change shift format
  shifts = list(edges = PhylogeneticEM::correspondenceEdges(res$shift.configuration,
                                                            trees_postorder[[paste0(X$ntaxa)]],
                                                            trees[[paste0(X$ntaxa)]]),
                values = res$shift.values,
                relativesTimes = 0)
  res$params_estims <- list(shifts = shifts,
                            variance = diag(res$sigma2),
                            selection.strength = diag(res$alpha),
                            optimal.value = res$intercept,
                            root.state = list(random = TRUE,
                                              stationary.root = TRUE,
                                              value.root = NA,
                                              exp.root = res$intercept,
                                              var.root = diag(res$sigma2/(2*res$alpha))))
  # total time
  res$total_time <- time_l1ou
  # number of equivalent solutions
  clusters <- PhylogeneticEM::clusters_from_shifts(trees[[paste0(X$ntaxa)]],
                                                   shifts$edges,
                                                   part.list = subtree.list[[paste0(X$ntaxa)]])
  Neq <- PhylogeneticEM:::extract.parsimonyNumber(PhylogeneticEM::parsimonyNumber(trees[[paste0(X$ntaxa)]],
                                                                                  clusters))
  # Summary
  res$results_summary <- data.frame(
    "log_likelihood" = sum(res$logLik),
    "number_equivalent_solutions" = Neq,
    "total_time" = time_l1ou["elapsed"],
    "K_select" = res$nShifts
  )
  ret <- list(sim = X,
              res = res)
  return(ret)
}

###############
## Forgottent subtreee.list
###############
subtree.list <- vector(mode = "list")
for (nta in c(128, 32, 64, 96, 160, 192, 256)){
  subtree.list[[paste0(nta)]] <- PhylogeneticEM:::enumerate_tips_under_edges(trees[[paste0(nta)]])
}

###############
## Estimations
###############

## Register parallel backend for computing
cl <- makeCluster(Ncores)
registerDoParallel(cl)

## Parallelized estimations
time_l1ou <- system.time(
  simestimations <- foreach(i = simlist, .packages = reqpckg) %dopar%
  {
    estimations_l1ou(i)
  }
)
# Stop the cluster (parallel)
stopCluster(cl)

## rename object and save
assign(paste0("simestimations_l1ou_", inference.index), 
       simestimations)
rm(simestimations)

save.image(paste0(saveresultfile, "_", datestamp_day, "_", inference.index, ".RData"))
