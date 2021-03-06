####################
## Parameters
####################
library(doParallel)
library(foreach)
library(ape)
library(quadrupen) # For Lasso initialization
library(robustbase) # For robust fitting of alpha
reqpckg <- c("ape", "quadrupen", "robustbase")

## Set number of parallel cores
Ncores <- 3

## Define date-stamp for file names
datestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
datestamp_day <- format(Sys.time(), "%Y-%m-%d")

## Load simulated data
datestamp_data <- "2015-03-17" #format(Sys.time(), "%Y-%m-%d")
savedatafile = "../Results/Simulations_Several_K/several_K_simlist"
saveresultfile <- "../Results/Simulations_Several_K/several_K_estimations"
load(paste0(savedatafile, "_", datestamp_data, ".RData"))

## These values should be erased by further allocations (generate_inference_files)
n.range <- n
inference.index <- 0

## Select data (according to the value of n)
n <- n

## Here n.range should be defined by generate_inference_files.R
simulations2keep <- sapply(simlist, function(x) { x$n %in% n.range }, simplify = TRUE)
simlist <- simlist[simulations2keep]
nbrSim <- length(simlist)

# ## Log file
# logfile <- paste0(savedatafile, "_alpha_known-", datestamp_day, "_", inference.index,"_log.txt")
# 
# log <- function(it){
#   txt <- paste0(Sys.time(), " : on batch ", inference.index, ", iteration ", it, " on ", nbrSim, " completed.")
#   writeLines(txt, logfile)
# }

######################
## Estimation Function
######################
estimations_several_K_alpha_known <- function(X){
  ## Inference function
  fun <- function(K_t){
    return(estimation_wrapper.OUsr(K_t, 
                                   phylo = trees[[paste0(X$ntaxa)]], 
                                   Y_data = X$Y_data, 
                                   times_shared = times_shared[[paste0(X$ntaxa)]], 
                                   distances_phylo = distances_phylo[[paste0(X$ntaxa)]], 
                                   T_tree = T_tree[[paste0(X$ntaxa)]],
                                   subtree.list = subtree.list[[paste0(X$ntaxa)]],
                                   h_tree = max(diag(times_shared[[paste0(X$ntaxa)]])[1:X$ntaxa]),
                                   alpha_known = TRUE,
                                   alpha = X$alpha))
  }
  ## Apply function for all K_try
  XX <- lapply(K_try[[paste0(X$ntaxa)]], fun)
  names(XX) <- K_try[[paste0(X$ntaxa)]]
  ## Formate results
  dd <- do.call(rbind, XX)
  df <- do.call(rbind, dd[ , "summary"])
  df <- as.data.frame(df)
  df$alpha  <- X$alpha
  df$gamma  <- X$gamma
  df$K <- X$K
  df$n <- X$n
  df$ntaxa <- X$ntaxa
  df$grp <- X$grp
  df$log_likelihood_true <- X$log_likelihood.true[1]
  df$difficulty <- X$difficulty
  ## Results
  X$results_summary <- df
  X$params_estim <- dd[, "params"]
  X$params_init_estim <- dd[, "params_init"]
  X$Zhat <- dd[, "Zhat"]
  X$m_Y_estim <- dd[, "m_Y_estim"]
  X$edge.quality <- dd[, "edge.quality"]
  return(X)
}

estimations_several_K <- function(X){
  ## Inference function
  fun <- function(K_t){
    return(estimation_wrapper.OUsr(K_t, 
                                   phylo = trees[[paste0(X$ntaxa)]], 
                                   Y_data = X$Y_data, 
                                   times_shared = times_shared[[paste0(X$ntaxa)]], 
                                   distances_phylo = distances_phylo[[paste0(X$ntaxa)]], 
                                   T_tree = T_tree[[paste0(X$ntaxa)]],
                                   subtree.list = subtree.list[[paste0(X$ntaxa)]],
                                   h_tree = max(diag(times_shared[[paste0(X$ntaxa)]])[1:X$ntaxa]),
                                   alpha_known = FALSE))
  }
  ## Apply function for all K_try
  XX <- lapply(K_try[[paste0(X$ntaxa)]], fun)
  names(XX) <- K_try[[paste0(X$ntaxa)]]
  ## Formate results
  dd <- do.call(rbind, XX)
  df <- do.call(rbind, dd[ , "summary"])
  df <- as.data.frame(df)
  df$alpha  <- X$alpha
  df$gamma  <- X$gamma
  df$K <- X$K
  df$n <- X$n
  df$ntaxa <- X$ntaxa
  df$grp <- X$grp
  df$log_likelihood_true <- X$log_likelihood.true[1]
  df$difficulty <- X$difficulty
  ## Results
  X$results_summary <- df
  X$params_estim <- dd[, "params"]
  X$params_init_estim <- dd[, "params_init"]
  X$alpha_0 <- dd[, "alpha_0"]
  X$Zhat <- dd[, "Zhat"]
  X$m_Y_estim <- dd[, "m_Y_estim"]
  X$edge.quality <- dd[, "edge.quality"]
  return(X)
}

# ############
# ## Estimations (alpha known)
# ############
# 
# ## Register parallel backend for computing
# cl <- makeCluster(Ncores)
# registerDoParallel(cl)
# 
# ## Parallelized estimations
# time_alpha_known <- system.time(
#   simestimations_alpha_known <- foreach(i = simlist, .packages = reqpckg) %dopar%
# {
#   estimations_several_K_alpha_known(i)
# }
# )
# # Stop the cluster (parallel)
# stopCluster(cl)
# 
# ## rename object and save
# assign(paste0("simestimations_alpha_known_", inference.index), 
#        simestimations_alpha_known)
# rm(simestimations_alpha_known)
# 
# save.image(paste0(saveresultfile, "_alpha_known-", datestamp_day, "_", inference.index, ".RData"))

############
## Estimations (alpha NOT known)
############

## Separate "favorable" values from others
simparams_keep <- subset(simparams, n %in% n.range)
favorables <- simparams_keep$gamma <= 1 & simparams_keep$alpha >= 3 & simparams_keep$K <= 5

## FAVORABLES ##
## Register parallel backend for computing
cl <- makeCluster(Ncores)
registerDoParallel(cl)

## Parallelized estimations
time_alpha_known <- system.time(
  simestimations_fav <- foreach(i = simlist[favorables], .packages = reqpckg) %dopar%
{
  estimations_several_K(i)
}
)
# Stop the cluster (parallel)
stopCluster(cl)

## rename object and save
assign(paste0("simestimations_fav_", inference.index), 
       simestimations_fav)
rm(simestimations_fav)

save.image(paste0(saveresultfile, "favorables-", datestamp_day, "_", inference.index, ".RData"))

## NOT FAVORABLES ##
## Register parallel backend for computing
cl <- makeCluster(Ncores)
registerDoParallel(cl)

## Parallelized estimations
time_alpha_known <- system.time(
  simestimations_unfav <- foreach(i = simlist[!favorables], .packages = reqpckg) %dopar%
{
  estimations_several_K(i)
}
)
# Stop the cluster (parallel)
stopCluster(cl)

## group favorables and unfavorables
simestimations <- vector(mode = "list", length = length(favorables))
simestimations[favorables] <- eval(as.name(paste0("simestimations_fav_", inference.index)))
simestimations[!favorables] <- simestimations_unfav

rm(simestimations_unfav)
rm(list = paste0("simestimations_fav_", inference.index))

## rename object and save
assign(paste0("simestimations_", inference.index), 
       simestimations)
rm(simestimations)

save.image(paste0(saveresultfile, "-", datestamp_day, "_", inference.index, ".RData"))
