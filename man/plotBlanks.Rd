% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotBlanks.R
\name{plotBlanks}
\alias{plotBlanks}
\title{Plot Raw Median Fluorescent Intensity Blanks Data}
\usage{
plotBlanks(antigen_output, experiment_name)
}
\arguments{
\item{antigen_output}{Output from `readAntigens()` (reactive).}

\item{experiment_name}{User-input experiment name (reactive).}
}
\value{
Bar plot showing whether MFI values for the blanks for each antigen
per plate is above or below the threshold MFI = 50 (ggplot).
}
\description{
This function gets the blank sample data and plots the blank sample Median
Fluorescent Intensity (MFI) values.
}
\author{
Shazia Ruybal-Pesantez, Dionne Argyropoulos
}
