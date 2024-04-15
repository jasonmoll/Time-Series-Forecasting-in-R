# Clear the working environment
rm(list = ls())

# Load necessary libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(forecast)
  library(earth) # for MARS
  library(mgcv) # for GAM
  library(nnet) # for Neural Networks
  library(randomForest) # for Random Forest
  library(lubridate)
})

#Print Job Start Time
start_time_pst <- with_tz(Sys.time(), "America/Los_Angeles")
print(start_time_pst)

# Set working directory
setwd('C:/Users/jmoll/Downloads')

# Read the data file & pre-process the data
data <- read_excel("./Staged_Data.xlsx") %>%
  filter(!is.na(VALUE) & !is.infinite(VALUE) & VALUE > 0) %>%
  mutate(VALUE = ifelse(VALUE == 0, NA, VALUE)) %>%
  na.omit()
# Declare the forecast horizon
horizon <- 730

# Prepare empty list to store results
results <- list()

# Loop through each ITEM to generate forecasts
unique_items <- unique(data$ITEM)
for(item in unique_items) {
  item_data <- filter(data, ITEM == item) %>% arrange(DATE)
  item_data$DATE_numeric <- as.numeric(item_data$DATE) - min(as.numeric(item_data$DATE)) + 1
  
  future_dates_numeric <- seq(from = max(item_data$DATE_numeric), length.out = horizon, by = 1)
  future_dates <- seq(max(item_data$DATE), by = "day", length.out = horizon)
  
  ts_data <- ts(item_data$VALUE, frequency = 365)
  
  # MARS Forecast
  mars_model <- earth(VALUE ~ DATE_numeric, data = item_data)
  future_dates_numeric <- seq(from = max(item_data$DATE_numeric), length.out = horizon, by = 1)
  mars_forecast <- predict(mars_model, newdata = data.frame(DATE_numeric = future_dates_numeric))
  
  # Double Exponential Smoothing
  if(length(ts_data) >= 2) {
    holt_model <- ets(ts_data, model = "AAN")
    holt_forecast <- forecast(holt_model, h = horizon)$mean
  } else {
    holt_forecast <- rep(NA, horizon)
  }
  
  # Check ts_data length for Holt-Winters and LOESS forecasts
  if(length(ts_data) >= 2.5*365) {
    hw_model <- HoltWinters(ts_data)
    hw_forecast <- forecast(hw_model, h = horizon)$mean
    
    stl_fit <- stl(ts_data, s.window = "periodic")
    loess_forecast <- forecast(stl_fit, h = horizon)$mean
  } else {
    hw_forecast <- rep(NA, horizon)
    loess_forecast <- rep(NA, horizon)
  }

  # Double Moving Average
  dma <- stats::filter(ts_data, rep(1/4, 4), sides = 2)
  dma_forecast <- if(length(dma) > 90) tail(dma, horizon, scale.y=FALSE) else rep(NA, horizon)  
  required_length <- horizon
  dma_length <- length(dma)
  if (dma_length < required_length) { # Repeat the last value if < horizon
    dma_forecast <- c(dma, rep(tail(dma, 1), required_length - dma_length))
  } else if (dma_length > required_length) {
   
    dma_forecast <- head(dma, required_length) # Cut the forecast if > horizon
  } else {
    dma_forecast <- dma
  }
  
  # Power Model
  log_item_data <- mutate(item_data, log_DATE = log(as.numeric(DATE)), log_VALUE = log(VALUE))
  power_model <- lm(log_VALUE ~ log_DATE, data = log_item_data)
  
  # Forecast future values
  log_future_dates_numeric <- log(seq(from = max(item_data$DATE_numeric) + 1, length.out = horizon, by = 1))
  predicted_log_values <- predict(power_model, newdata = data.frame(log_DATE = log_future_dates_numeric))
  
  # Exponentiate to get back to the original scale
  power_forecast <- exp(predicted_log_values)
  
  # Create data frame to align future dates with forecasts
  #future_dates <- seq(max(item_data$DATE), by = "day", length.out = horizon)
  
  # Generalized Additive Model (GAM)
  gam_model <- gam(VALUE ~ s(DATE_numeric), data = item_data)
  gam_forecast <- predict(gam_model, newdata = list(DATE_numeric = future_dates_numeric))
  
  # Polynomial Regression
  poly_model <- lm(VALUE ~ poly(DATE_numeric, degree = 2), data = item_data)
  poly_forecast <- predict(poly_model, newdata = data.frame(DATE_numeric = future_dates_numeric))
  
  # Random Forest
  rf_model <- randomForest(VALUE ~ DATE_numeric, data = item_data)
  rf_forecast <- predict(rf_model, newdata = data.frame(DATE_numeric = future_dates_numeric))

  
  # Prepare the forecast data frame
  forecast_data <- tibble(
    ITEM = rep(item, horizon),
    DATE = future_dates,
    VALUE = rep(NA, horizon), # Forecasted values are NA because they're unknown
    HW = hw_forecast,
    LOESS = loess_forecast,
    DMA = dma_forecast,
    MARS = mars_forecast,
    HOLT = holt_forecast,
    POWER = power_forecast,
    GAM = gam_forecast,
    POLY = poly_forecast,
    RF = rf_forecast
  )
  
  # Combine historical and forecast data
  combined_data <- bind_rows(item_data %>% select(ITEM, DATE, VALUE), forecast_data)
  
  # Store combined data in the results list
  results[[item]] <- combined_data
}

# Combine results into one data frame
final_results <- bind_rows(results)

# Plotting - Useful when forecasting a single time series ... less so for larger data sets.
#ggplot(final_results, aes(x = DATE)) +
#  geom_line(aes(y = VALUE, colour = "Historical"), data = filter(final_results, !is.na(VALUE))) +
#  geom_line(aes(y = HW, colour = "Holt-Winters Forecast"), data = filter(final_results, !is.na(HW))) +
#  geom_line(aes(y = LOESS, colour = "LOESS Forecast"), data = filter(final_results, !is.na(LOESS))) +
#  geom_line(aes(y = MARS, colour = "MARS Forecast"), data = filter(final_results, !is.na(MARS))) +
#  theme_minimal() +
#  labs(title = "Historical Data and Forecasts", x = "Date", y = "Value")

# Display the first few rows of the final results to check
#head(final_results, 15)

# Save results to a new csv file
setwd('C:/Users/jmoll/Downloads')
write.csv(final_results,"./output.csv", row.names=FALSE)

#Print Job Completed Time
end_time_pst <- with_tz(Sys.time(), "America/Los_Angeles")
print(start_time_pst)
print(end_time_pst)

# Clear existing variables
rm(list = ls())

