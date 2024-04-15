# Time-Series-Forecasting-in-R
Basic Time-Series Forecasting Script

## Overview
This script performs advanced time series forecasting on continuous historical data using various forecasting techniques including MARS, Holt-Winters, LOESS, Double Moving Average, Power Model, GAM, Polynomial Regression, and Random Forest. The script is intended for use in R.

## Prerequisites
Before running this script, ensure you have the following:
- R installed on your machine.
- Required R libraries installed: `tidyverse`, `readxl`, `forecast`, `earth`, `mgcv`, `nnet`, `randomForest`, and `lubridate`.

## Installation
1. Install the necessary R packages if you haven't already:
   ```R
   install.packages(c("tidyverse", "readxl", "forecast", "earth", "mgcv", "nnet", "randomForest", "lubridate"))

## Data Requirements
Ensure your data is in an Excel file named Staged_Data.xlsx.
The script expects the following columns: ITEM, DATE, VALUE
Modify the setwd() path in the script to match your data's location.

## Running the Script
To run the script:

1. Open your R environment.
2. Set the working directory to where the script is located.
3. Run the script by sourcing it:
      source('path_to_script.R')

## Output
The script generates forecasts for each unique item identified in the data.

Forecasts are stored in a list of data frames, with each frame corresponding to a unique item.

The results are saved as output.csv in the working directory. Because of the number of potential combinations in the data, importing the results into Excel and creating a visualizing in a pivot report is a recommended next step.

The script prints the start and end time of the execution in the console to track runtimes.

## Important Notes
The script clears the R environment at the beginning and the end of execution to ensure a clean run. Ensure you save any important data before running this script.

Debugging and customizing the forecasting methods may require intermediate to advanced knowledge of R and time series analysis.

## Troubleshooting

If you encounter errors related to missing packages, recheck the installation section and ensure all packages are correctly installed.

Ensure the data file is correctly formatted and placed as specified in the Data Requirements section.

Errors in the console output often provide hints on what might be wrong; check the line number and error description for troubleshooting.
