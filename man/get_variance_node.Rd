% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/E_step.R
\name{get_variance_node}
\alias{get_variance_node}
\title{Get variance matrix of a node}
\usage{
get_variance_node(node, vars)
}
\arguments{
\item{node}{for which to extract the matrix.}

\item{vars}{matrix of size p x p*(ntaxa+Nnode) result of function \code{compute_E.simple},
entry "variances" or "covariances".}
}
\value{
sub-matrix of variance for the node.
}
\description{
\code{get_variance_node} returns the conditional variance of a node, or the conditional
covariance of a node and its parent.
}
\keyword{internal}
