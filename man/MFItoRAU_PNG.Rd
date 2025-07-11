% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/MFItoRAU_PNG.R
\name{MFItoRAU_PNG}
\alias{MFItoRAU_PNG}
\title{Median Fluorescent Intensity (MFI) to Relative Antibody Units (RAU)
conversion based on PNG standard}
\usage{
MFItoRAU_PNG(antigen_output, plate_list, counts_QC_output)
}
\arguments{
\item{antigen_output}{Output from `readAntigens()` (reactive).}

\item{plate_list}{Output from `readPlateLayout()` (reactive).}

\item{counts_QC_output}{Output from `getCountsQC()` (reactive).}
}
\value{
A list of three data frames:
1. Data frame with  MFI data, converted RAU data and matched SampleID's.
2. Plot information for `plotModel` function
3. Data frame of RAU data for random forest classification use.
}
\description{
This function fits a 5-parameter logistic standard curve to the dilutions
of the positive controls for each protein and converts the MFI values
into relative antibody units (RAU) written by Connie Li Wai Suen.
}
\author{
Connie Li Wai Suen, Dionne Argyropoulos
}
