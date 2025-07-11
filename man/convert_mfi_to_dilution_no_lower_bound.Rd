% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convert_mfi_to_dilution_no_lower_bound.R
\name{convert_mfi_to_dilution_no_lower_bound}
\alias{convert_mfi_to_dilution_no_lower_bound}
\title{Convert mfi to dilution using known standard curve fit and no lower bound}
\usage{
convert_mfi_to_dilution_no_lower_bound(mfi, params, min_relative_dilution)
}
\arguments{
\item{mfi}{Known mfi of samples}

\item{params}{Known parameters for five parameter logistic fit.}

\item{min_relative_dilution}{Known minimum value of dilution in the standard curve. Relative means setting S1 to a dilution/RAU/concentration of 1.}
}
\value{
Returns the dilution of each sample in mfi.
}
\description{
Convert mfi to dilution using known standard curve fit and no lower bound unless you are below the asymptote of the standard curve.
In this situation we set your value to min_relative_dilution. I dunno argue?
}
\author{
Eamon Conway
}
