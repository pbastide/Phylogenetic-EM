% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/shifts_manipulations.R
\name{init.incidence.matrix}
\alias{init.incidence.matrix}
\title{Initialization for incidence matrix}
\usage{
init.incidence.matrix(phy)
}
\arguments{
\item{phy}{Input tree.}
}
\value{
Matrix with Nnode rows and ntaxa column.
}
\description{
\code{init.incidence.matrix} initialize the matrix updated in
\code{update.incidence.matrix} for the computation of the incidence matrix
in \code{incidence.matrix}.
}
\details{
The initialized matrix has ntaxa column and Nnode rows. Each node
represent its parental branch. A row corresponding to a tip i is initialized
to a vector of zeros, with only entry i equal to one. (Branch ending at 
tip i is only in the i^th lineage)
}
\keyword{internal}
