% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotCounts.R
\name{plotCounts}
\alias{plotCounts}
\title{Plot Bead Count Data}
\usage{
plotCounts(counts_output, experiment_name)
}
\arguments{
\item{counts_output}{Output from `getCounts()` (reactive).}

\item{experiment_name}{User-input experiment name (reactive).}
}
\value{
Tile Plot showing binary result of "sufficient beads" with cut-off
>15 beads and "repeat" ≤15 beads (ggplot).
}
\description{
This function gets the count data and plots the plate image, creating a new
facet (i.e., panel) for each antigen and each line represents the
different plates so that they can be visualised.
}
\author{
Shazia Ruybal-Pesántez, Dionne Argyropoulos
}
