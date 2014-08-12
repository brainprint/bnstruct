% Generated by roxygen2 (4.0.1): do not edit by hand
\docType{methods}
\name{cpts<-}
\alias{cpts<-}
\alias{cpts<-,BN-method}
\title{set the list of conditional probability tables of a network.}
\usage{
cpts(x) <- value
}
\arguments{
\item{x}{an object.}

\item{value}{list of the conditional probability tables of the object.}
}
\description{
Set the list of conditional probability tables of a \code{\link{BN}} object.
}
\details{
Each conditional probability table is represented as a multidimensional array.
To retrieve single dimensions (e.g. to compute marginals), users should provide dimensions names.
}
