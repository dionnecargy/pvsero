% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/readPlateLayout.R
\name{readPlateLayout}
\alias{readPlateLayout}
\title{Read Plate Layout/s}
\usage{
readPlateLayout(plate_layout, antigen_output)
}
\arguments{
\item{plate_layout}{An ".xlsx" file with sheets labelled plate1, plate2...
etc. (reactive).}

\item{antigen_output}{Output from `readAntigens()` (reactive).}
}
\value{
A list of data frames, with each one representing an individual plate.
}
\description{
This function imports the plate layout. Each sheet of the plate layout
".xlsx" file must contain 13 columns (labelled
Plate, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) (columns A-M) and 9 rows
(Plate, A, B, C, D, E, F, G, H) (rows 1-9). *Note that the first row/column
i.e., the A1 cell in excel is called "Plate". This function also checks that
the plate sheet labels are consistent with the MAGPIX file input names, as a
check prior to merging downstream.
}
\author{
Shazia Ruybal-Pesántez, Dionne Argyropoulos
}
