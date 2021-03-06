% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/generic_functions.R
\name{check_range_alpha}
\alias{check_range_alpha}
\title{Check range of alpha}
\usage{
check_range_alpha(alpha, h_tree)
}
\arguments{
\item{alpha}{a vector of alpha values.}

\item{h_tree}{the total height of the tree.}
}
\description{
Check that the chosen values of alpha are not too large
or too small, in order to avoid numerical instabilities.
}
\keyword{internal}
