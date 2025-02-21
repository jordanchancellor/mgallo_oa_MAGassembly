# create an abundance count table from coverm summed counts for each MAG
setwd("/project/noujdine_61/jchancel/microbiome_gallo_oa/")
Matrix <- matrix(NA, nrow = 12, ncol = 9) # number of columns = number of samples; number of tows = number of mags
samples_file<-read.delim("samples_file.txt", header = F)
samples<-list(samples_file)
mydata <- data.frame(matrix = Matrix)
colnames(mydata) <- unlist(samples)
MAG_list<-read.delim("taxonomy/final_fasta/ALL_MAGs_contiglist.txt", header = F)
MAGs<-list(MAG_list)
mydata$contig<-unlist(MAGs)
mydata$contig<-gsub(x = mydata$contig, pattern = ".fa", replacement = "")
mydata<-mydata[,c(10,1:9)]

# list abundance files
files <- list.files("abundance/coverm/ALL_MAGs/counts/", pattern = "*.tsv", full.names = TRUE)

# Function to extract sample and contig from filename
extract_info <- function(filename) {
  parts <- unlist(strsplit(basename(filename), "_mapped_"))
  sample <- parts[1]
  contig <- sub("_abundance.tsv$", "", parts[2])
  list(sample = sample, contig = contig)
}

# Initialize the dataframe with zeroes
mydata[is.na(mydata)] <- 0

# Loop through each file and extract trimmed mean value
for (file in files) {
  # Extract sample and contig information
  info <- extract_info(file)
  sample <- info$sample
  contig <- info$contig
  
  # Debug: Print the extracted sample and contig
  cat("Processing file:", file, "\n")
  cat("Sample:", sample, "\n")
  cat("Contig:", contig, "\n")
  
  # Check if the sample column exists in the dataframe
  if (sample %in% colnames(mydata)) {
    # Read the file
    data <- tryCatch(read.delim(file, header = FALSE), error = function(e) NULL)
    
    if (!is.null(data) && ncol(data) >= 2) {
      # Extract the second value from the second column
      values <- unlist(strsplit(as.character(data[1, 2]), " "))
      if (length(values) >= 2) {
        value <- as.numeric(values[2])
        
        # Debug: Print the extracted value
        cat("Value:", value, "\n")
        
        # Ensure that the value is not NULL
        if (!is.null(value)) {
          # Update the dataframe
          mydata[mydata$contig == contig, sample] <- value
        }
      } else {
        cat("Insufficient number of values in the second column\n")
      }
    } else {
      # Debug: Print a message if data is NULL or doesn't have enough columns
      cat("Data is NULL or does not have at least 2 columns\n")
    }
  } else {
    # Debug: Print a message if sample column does not exist in the dataframe
    cat("Sample column does not exist in the dataframe\n")
  }
}

# Replace NA values with zeroes
mydata[is.na(mydata)] <- 0

# Print the updated dataframe
print(mydata)

# save data frame
write.csv(mydata, file = "MG22_OA_trimmedmeancounts.csv", quote = FALSE, row.names = FALSE)
