#' Read Raw Serological Data
#'
#' This function imports the raw data from the Magpix or Bioplex machine
#' and matches the sample names from the plate layout based on their plate/well
#' location.
#'
#' @param raw_data String with the raw data path (reactive).
#' @param raw_data_filenames String with the raw data filenames (reactive).
#' @param platform "magpix" or "bioplex" (reactive).
#' @return List of data frames: (i) raw data output, (ii) cleaned all results
#' (iii) count data, (iv) blanks only, (v) standards only, (vi) run
#' information.
#' @export
#' @importFrom tools file_ext
#' @importFrom readxl read_excel
#' @importFrom meltr melt_csv2 melt_csv
#' @importFrom dplyr select filter across any_of bind_rows left_join arrange mutate
#' @importFrom tidyr pivot_wider
#' @importFrom janitor row_to_names
#' @author Shazia Ruybal-Pesántez, Dionne Argyropoulos
readSeroData <- function(raw_data, raw_data_filenames, platform){

  platemap_file <- system.file("extdata", "platemap.csv", package = "pvsero")
  platemap <- read.csv(platemap_file)

  # Initialise master list to store files
  master_list <- list(
    data_raw  = NULL,  # Placeholder for raw data combined across files
    results   = NULL,  # Placeholder for processed results combined
    counts    = NULL,  # Placeholder for any count data combined
    blanks    = NULL,  # Placeholder for any blanks data combined
    stds      = NULL,  # Placeholder for any stds data combined
    run       = NULL   # Placeholder for any run data combined
  )

  # Loop through each file and process accordingly
  for (i in seq_along(raw_data)) {
    file <- raw_data[i]
    file_name <- raw_data_filenames[i]

    if (checkPlatform(file, platform) == TRUE) {
      message("PASS: File ", file_name, " successfully validated.")
    }

    if (platform == "magpix") {

      file_extension <- tools::file_ext(file)  # Identify the file extension and read the file accordingly

      if (file_extension == "xlsx") {
        full <- suppressMessages(readxl::read_excel(file))
        df <- as.data.frame(full)

        data_raw <- df

        median_row_number     <- which(df$xPONENT == "Median")
        endmedian_row_number  <- which(df$xPONENT == "Net MFI")
        count_row_number      <- which(df$xPONENT == "Count")
        endcount_row_number   <- which(df$xPONENT == "Avg Net MFI")

        results <- suppressMessages(readxl::read_excel(file, skip = median_row_number + 1, n_max = endmedian_row_number - median_row_number - 2))
        counts <- suppressMessages(readxl::read_excel(file, skip = count_row_number + 1, n_max = endcount_row_number - count_row_number - 2, col_names = TRUE))
        run <- suppressMessages(readxl::read_excel(file, n_max = median_row_number))

      } else if (file_extension == "csv") {

        first_lines <- readLines(file, n = 5)           # Read the first few lines of the file

        if (any(grepl(";", first_lines))) {
          # IF EUROPEAN CSV WITH ; DELLIMITER
          csv <- suppressWarnings(meltr::melt_csv2(file))
        } else {
          # IF CONVENTIONAL CSV WITH , DELLIMITER
          csv <-  suppressMessages(meltr::melt_csv(file))
        }

        full <- csv %>%
          dplyr::select(-data_type) %>%
          tidyr::pivot_wider(id_cols = row, names_from = col, values_from = value) %>%
          dplyr::select(-row)
        full <- filter(full, rowSums(is.na(full)) != ncol(full))

        df <- suppressWarnings(as.data.frame(full) %>% janitor::row_to_names(row_number = 1))
        data_raw <- df

        median_row_number     <- which(df$xPONENT == "Median")
        endmedian_row_number  <- which(df$xPONENT == "Net MFI")
        count_row_number      <- which(df$xPONENT == "Count")
        endcount_row_number   <- which(df$xPONENT == "Avg Net MFI")

        results <- df[(median_row_number + 1):(endmedian_row_number - 1), ]
        colnames(results) <- results[1, ]
        results <- results[-1, ]
        results <- results[, colSums(!is.na(results)) > 0] # remove NA columns
        results <- results[rowSums(!is.na(results)) > 0, ] # remove NA rows
        rownames(results) <- NULL

        counts <- df[(count_row_number + 1):(endcount_row_number - 1), ]
        counts <- counts[, colSums(!is.na(counts)) > 0] # remove NA columns
        counts <- counts[rowSums(!is.na(counts)) > 0, ] # remove NA rows
        colnames(counts) <- counts[1, ]
        counts <- counts[-1, ]
        rownames(counts) <- NULL

        run <- df[1:median_row_number, ]
        run <- run[, colSums(!is.na(run)) > 0] # remove NA columns
        run <- run[rowSums(!is.na(run)) > 0, ] # remove NA rows
        rownames(run) <- NULL

      } else {
        stop("Unsupported file format! Please use .csv or .xlsx")
      }

      # 2. Create results
      results <- results %>%
        dplyr::select(-dplyr::any_of("Total Events")) %>%
        dplyr::mutate(dplyr::across(everything(), ~ gsub("NaN", 0, .))) %>% # Change "NaN" to 0s
        dplyr::mutate(Sample = ifelse(Sample == "Blank", paste0("Blank", row_number()),
                                      ifelse(Sample == "B", paste0("Blank", row_number()), Sample))) %>% # Sequentially relabel Blank rows and keep other Sample values unchanged
        dplyr::mutate(Sample = ifelse(Sample == "S", paste0("S", cumsum(Sample == "S")), Sample)) # Sequentially relabel Sample rows and keep other Sample values

      # 3. Load counts for QC
      counts <- counts %>%
        dplyr::mutate(Sample = ifelse(Sample == "Blank", paste0("Blank", row_number()),
                                      ifelse(Sample == "B", paste0("Blank", row_number()), Sample))) %>% # Sequentially relabel Blank rows and keep other Sample values unchanged
        dplyr::select(-any_of("Total Events"))
      counts <- tidyr::as_tibble(counts)

      # 4. Save blanks
      blanks <- results %>% dplyr::filter(grepl("Blank|^B$", Sample, ignore.case = TRUE))

      # 5. Save standards
      stds <- results %>% dplyr::filter(grepl("^S", Sample, ignore.case = TRUE))

      # 6. Save run info
      run_info <- as.data.frame(run) %>% dplyr::select(Program:xPONENT)

      # Ensure blanks exist
      if (nrow(blanks) == 0) {
        stop("No blanks were found in the dataset. Ensure blanks are properly labeled.")
      }

      # Ensure standards exist
      if (nrow(stds) == 0) {
        stop("No standards were found in the dataset. Ensure standards are properly labeled.")
      }

      # Save the plate number for this file
      plate_numbers <- file_name %>% stringr::str_extract("(?i)(repeat)?plate\\d+(?=[._-]|$)")

      # Add 'plate' column to each dataframe
      data_raw$Plate <- plate_numbers
      results$Plate <- plate_numbers
      counts$Plate <- plate_numbers
      blanks$Plate <- plate_numbers
      stds$Plate <- plate_numbers
      run_info$Plate <- plate_numbers

      # Add processed file's tables to the master list
      master_list$data_raw <- suppressMessages(dplyr::bind_rows(master_list$data_raw, data_raw))   # Combine raw data
      master_list$results  <- dplyr::bind_rows(master_list$results, results)     # Combine processed results
      master_list$counts   <- dplyr::bind_rows(master_list$counts, counts)       # Combine counts
      master_list$blanks   <- dplyr::bind_rows(master_list$blanks, blanks)       # Combine blanks
      master_list$stds     <- dplyr::bind_rows(master_list$stds, stds)           # Combine stds
      master_list$run      <- dplyr::bind_rows(master_list$run, run_info)        # Combine run

    } else if (platform == "bioplex") {

      file_extension <- tools::file_ext(file)     # Identify the file extension and read the file accordingly

      if (file_extension == "xlsx") {

        full <- suppressMessages(readxl::read_excel(file))
        df <- as.data.frame(full)

      } else if (file_extension == "csv") {

        first_lines <- readLines(file, n = 5)           # Read the first few lines of the file

        if (any(grepl(";", first_lines))) {
          # IF EUROPEAN CSV WITH ; DELLIMITER
          csv <- suppressWarnings(meltr::melt_csv2(file))
        } else {
          # IF CONVENTIONAL CSV WITH , DELLIMITER
          csv <-  suppressMessages(meltr::melt_csv(file))
        }

        df <- as.data.frame(full)

      } else {
        stop("Unsupported file format! Please use .csv or .xlsx")
      }

      colnames(df)[1] <- "Run" # Renames first column name as it is named by the local computer
      data_raw <- df # Save Raw File

      # 2. Create results
      df_cleaned <- which(df[,2] == "Type")
      df <- df[df_cleaned:nrow(df), ] # Remove first few rows
      colnames(df) <- as.character(df[1,])
      rownames(df_cleaned) <- NULL
      df <- df[-1,]

      colnames(df) <- gsub("\\s*\\(.*\\)", "", colnames(df)) # Clean up column names
      df <- df %>%
        dplyr::mutate(Type = ifelse(Type == "B", "Blank", Type), # Re-label
                      suffix = as.numeric(gsub("\\D", "", Type)), # Order so that standards and blanks are at the top
                      prefix = substr(Type, 1, 1)) %>% # Order so that standards and blanks are at the top
        dplyr::arrange(prefix, suffix) %>% # Order so that standards and blanks are at the top
        dplyr::left_join(platemap, by = "Well") %>%  # Join on the Well column
        dplyr::select(-c(prefix, suffix, Region, Gate, Total, `% Agg Beads`, `Sampling Errors`, Well, dplyr::any_of("Description"))) %>% # Remove unnecessary columns, including Description if it exists
        dplyr::select(Location, Sample = Type, everything()) %>% # Rename columns to be same as magpix
        dplyr::mutate(dplyr::across(everything(), ~ gsub("NaN", 0, .)),  # Change "NaN" to 0s
                      dplyr::across(everything(), ~ gsub("\\*\\*\\*", "0", .)), #Change "***" to 0s
                      Sample = ifelse(Sample == "Blank", paste0("Blank", row_number()), Sample)) # Sequentially relabel Blank rows and keep other Sample values unchanged

      results <- df %>% dplyr::mutate(dplyr::across(-c(Location, Sample), ~ gsub("\\s*\\(.*\\)", "", .)))

      # 3. Load counts for QC
      counts <- df %>% dplyr::mutate(dplyr::across(-c(Location, Sample), ~ gsub(".*\\((.*)\\).*", "\\1", .)))

      # 4. Save blanks
      blanks <- results %>% dplyr::filter(grepl("Blank", Sample, ignore.case = TRUE))

      # 5. Save standards
      stds <- results %>% dplyr::filter(grepl("^S", Sample, ignore.case = TRUE))

      # 6. Save run info
      well_row <- which(data_raw[,1] == "Well")[1] # [1] ensures only the first occurrence
      run_info <- data_raw[1:(well_row-2), 1, drop = FALSE] # Save run info

      # Ensure blanks exist
      if (nrow(blanks) == 0) {
        stop("No blanks were found in the dataset. Ensure blanks are properly labeled.")
      }

      # Ensure standards exist
      if (nrow(stds) == 0) {
        stop("No standards were found in the dataset. Ensure standards are properly labeled.")
      }

      # Save the plate number for this file
      plate_numbers <- file_name %>% stringr::str_extract("(?i)(repeat)?plate\\d+(?=[._-]|$)")

      # Add 'plate' column to each dataframe
      data_raw$Plate <- plate_numbers
      results$Plate <- plate_numbers
      counts$Plate <- plate_numbers
      blanks$Plate <- plate_numbers
      stds$Plate <- plate_numbers
      run_info$Plate <- plate_numbers

      # Stitch together for master file
      master_list$data_raw <- suppressMessages(bind_rows(master_list$data_raw, data_raw))   # Combine raw data
      master_list$results  <- bind_rows(master_list$results, results)     # Combine processed results
      master_list$counts   <- bind_rows(master_list$counts, counts)       # Combine counts
      master_list$blanks   <- bind_rows(master_list$blanks, blanks)       # Combine blanks
      master_list$stds     <- bind_rows(master_list$stds, stds)           # Combine stds
      master_list$run      <- bind_rows(master_list$run, run_info)        # Combine run

    } else {
      stop("Unsupported file type. Please use either Magpix or Bioplex!")
    }
  }

  return(master_list)

}
