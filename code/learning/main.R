######################################################################
# Author: Begum Topcuoglu
# Date: 2018-12-20
# Title: Main pipeline for 7 classifiers in R programming language
######################################################################

######################################################################
# Description:

# This script will read in data from Baxter et al. 2016
#     - 0.03 subsampled OTU dataset
#     - CRC metadata: SRN information


# It will run the following machine learning pipelines:
#     - L2 Logistic Regression
#     - L2 Linear SVM
######################################################################

######################################################################
# Dependencies and Outputs:

# Be in the project directory.

# The outputs are:
#   (1) AUC values for cross-validation and testing for each data-split
#   (2) meanAUC values for each hyper-parameter tested during each split.
######################################################################


################### IMPORT LIBRARIES and FUNCTIONS ###################
# The dependinces for this script are consolidated in the first part
deps = c("tidyverse", "caret" ,"rpart", "xgboost", "randomForest", "kernlab","LiblineaR", "pROC");
for (dep in deps){
  if (dep %in% installed.packages()[,"Package"] == FALSE){
    install.packages(as.character(dep), quiet=TRUE, repos = "http://cran.us.r-project.org", dependencies=TRUE);
  }
  library(dep, verbose=FALSE, character.only=TRUE)
}
# Load in needed functions and libraries
source('code/learning/model_selection.R')
source('code/learning/model_pipeline.R')
source('code/learning/generateAUCs.R')
source('code/learning/model_interpret.R')

######################################################################

######################## DATA PREPARATION #############################
# Features: Hemoglobin levels(FIT) and 16S rRNA gene sequences(OTUs) in the stool
# Labels: - Colorectal lesions of 490 patients.
#         - Defined as cancer or not.(Cancer here means: SRN)
#                                     SRNs are adv adenomas+carcinomas

# Read in metadata and select only sample Id and diagnosis columns
meta <- read.delim('data/metadata.tsv', header=T, sep='\t') %>%
  select(sample, Dx_Bin, fit_result)
# Read in OTU table and remove label and numOtus columns
shared <- read.delim('data/baxter.0.03.subsample.shared', header=T, sep='\t') %>%
  select(-label, -numOtus)
# Merge metadata and OTU table.
# Group advanced adenomas and cancers together as cancer and normal, high risk normal and non-advanced adenomas as normal
# Then remove the sample ID column
data <- inner_join(meta, shared, by=c("sample"="Group")) %>%
  mutate(dx = case_when(
    Dx_Bin== "Adenoma" ~ "normal",
    Dx_Bin== "Normal" ~ "normal",
    Dx_Bin== "High Risk Normal" ~ "normal",
    Dx_Bin== "adv Adenoma" ~ "cancer",
    Dx_Bin== "Cancer" ~ "cancer"
  )) %>%
  select(-sample, -Dx_Bin) %>%
  drop_na()
# We want the diagnosis column to be a factor
data$dx <- factor(data$dx, labels=c("normal", "cancer"))
###################################################################

######################## RUN PIPELINE #############################
# Choose which classification methods we want to run on command line
#                "L2_Logistic_Regression",
#                "L2_Linear_SVM",


# We want to get walltime for each model for and each data-split t
start_time <- Sys.time()

# We will run main.R from command line with arguments
#  - These arguments will be saved into variable "input"
#  - First argument is the seed number which is the array index
#  - Second argument is the model name (one of the list above)
input <- commandArgs(trailingOnly=TRUE)
seed <- as.numeric(input[1])
model <- input[2]
# Then arguments 1 and 2 will be placed respectively into the functions:
#   1. set.seed() : creates reproducibility and variability
#   2. get_results(): self-defined function that
#                     - runs the modeling pipeline
#                     - saves performance and hyper-parameters and imp features
set.seed(seed)
get_results(data, model, input[1])

# We get wall-time for pipeline
end_time <- Sys.time()
print(end_time - start_time)
###################################################################
