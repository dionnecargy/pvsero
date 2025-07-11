% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/readAntigens.R
\name{readAntigens}
\alias{readAntigens}
\title{Standardise Antigen Names}
\usage{
readAntigens(serodata_output)
}
\arguments{
\item{serodata_output}{Output of `readSeroData`}
}
\value{
List of data frames with relabelled column names for our antigen names.
}
\description{
This function ensures that the antigens in the raw data adheres to our
nomenclature format in the data processing and model steps. This relies on
the output of the `readSeroData` to then use our nomenclature for the eight
antigens of interest in PvSeroApp.
}
\author{
Dionne Argyropoulos
}
