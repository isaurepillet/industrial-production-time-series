# ============================================================
# Industrial Production Time Series Analysis
# ============================================================
#
# Authors: Camille Legrée-Haghbarth and Isaure Pillet
# Institution: ENSAE Paris
#
# Description:
# Time-series analysis and forecasting of the French industrial
# production index for the manufacture of food products,
# beverages and tobacco products.
#
# Data source: INSEE
# Frequency: Monthly
# Sample: January 1990 - March 2025
#
# ============================================================


# 1. Packages -------------------------------------------------

library(tidyverse)
library(lubridate)
library(forecast)
library(tseries)
library(urca)
library(gridExtra)
library(ellipse)

# Create output directory if needed
dir.create("figures", showWarnings = FALSE)

# 2. Data import and preparation ------------------------------

# The original INSEE data are stored in the data/ directory.
raw_data <- read.csv(
  "data/valeurs_mensuelles.csv",
  sep = ";",
  header = FALSE
)

# Remove metadata rows and assign variable names.
data <- raw_data[4:nrow(raw_data), ]

colnames(data) <- c("date", "value", "code")

data <- data %>%
  mutate(
    date = ymd(paste0(date, "-01")),
    value = as.numeric(value)
  ) %>%
  select(date, value) %>%
  drop_na()


# 3. Exploratory analysis -------------------------------------

# Plot the original industrial production series.
ggplot(data, aes(x = date, y = value)) +
  geom_line(linewidth = 0.6) +
  labs(
    title = "French Industrial Production",
    subtitle = "Manufacture of food products, beverages and tobacco products",
    x = NULL,
    y = "Industrial production index"
  ) +
  theme_minimal(base_size = 13)


# Log transformation.
data <- data %>%
  mutate(log_value = log(value))

ggplot(data, aes(x = date, y = log_value)) +
  geom_line(linewidth = 0.6) +
  labs(
    title = "Log-transformed Industrial Production Index",
    x = NULL,
    y = "log(IPI)"
  ) +
  theme_minimal(base_size = 13)


# Convert the log-transformed series to a monthly time-series object.
ts_log <- ts(
  data$log_value,
  start = c(year(min(data$date)), month(min(data$date))),
  frequency = 12
)


# 4. Seasonality and stationarity -----------------------------

# Test whether the distribution of the series differs across months.
data <- data %>%
  mutate(
    month = factor(month(date)),
    year = year(date)
  )

kruskal.test(log_value ~ month, data = data)


# Augmented Dickey-Fuller and KPSS tests on the log series.
adf.test(data$log_value)
kpss.test(data$log_value)


# First difference of the logarithmic series.
data <- data %>%
  mutate(
    log_diff = c(NA, diff(log_value))
  )

data_diff <- data %>%
  drop_na(log_diff)


# Stationarity tests after first differencing.
adf.test(data_diff$log_diff)
kpss.test(data_diff$log_diff)


# 5. Visualisation of the transformation ----------------------

p_original <- ggplot(data, aes(x = date, y = value)) +
  geom_line(linewidth = 0.6) +
  labs(
    title = "Original Industrial Production Index",
    x = NULL,
    y = "Index"
  ) +
  theme_minimal(base_size = 13)


p_stationary <- ggplot(data, aes(x = date, y = log_diff)) +
  geom_line(linewidth = 0.6) +
  labs(
    title = "Log-Differenced Series",
    x = NULL,
    y = expression(log(X[t]) - log(X[t-1]))
  ) +
  theme_minimal(base_size = 13)


grid.arrange(
  p_original,
  p_stationary,
  ncol = 1
)


# 6. ACF and PACF ---------------------------------------------

log_diff <- na.omit(data$log_diff)

ts_log_diff <- ts(
  log_diff,
  start = c(1990, 2),
  frequency = 12
)

par(mfrow = c(1, 2))

acf(
  ts_log_diff,
  main = "Autocorrelation Function"
)

pacf(
  ts_log_diff,
  main = "Partial Autocorrelation Function"
)

par(mfrow = c(1, 1))


# 7. ARMA model selection -------------------------------------

# Estimate candidate ARMA(p,q) specifications and compare them
# using AIC, BIC and the Ljung-Box residual autocorrelation test.

model_results <- data.frame(
  model = character(),
  p = integer(),
  q = integer(),
  AIC = numeric(),
  BIC = numeric(),
  ljung_box_pvalue = numeric()
)


for (p in 0:4) {

  for (q in 0:2) {

    fit <- tryCatch(
      {
        Arima(
          ts_log_diff,
          order = c(p, 0, q),
          include.mean = FALSE
        )
      },
      error = function(e) NULL
    )

    if (!is.null(fit)) {

      ljung_box <- Box.test(
        residuals(fit),
        lag = 10,
        type = "Ljung-Box",
        fitdf = p + q
      )

      model_results <- rbind(
        model_results,
        data.frame(
          model = paste0("ARMA(", p, ",", q, ")"),
          p = p,
          q = q,
          AIC = AIC(fit),
          BIC = BIC(fit),
          ljung_box_pvalue = ljung_box$p.value
        )
      )
    }
  }
}


# Rank candidate models by AIC.
model_results <- model_results %>%
  arrange(AIC)

print(model_results)


# 8. Selected ARMA(1,1) model ---------------------------------

arma_11 <- Arima(
  ts_log_diff,
  order = c(1, 0, 1),
  include.mean = FALSE
)

summary(arma_11)


# 9. Model diagnostics ----------------------------------------

arma_residuals <- residuals(arma_11)


# Test whether residuals have zero mean.
t.test(
  arma_residuals,
  mu = 0
)


# Ljung-Box test for residual autocorrelation.
Box.test(
  arma_residuals,
  lag = 10,
  type = "Ljung-Box",
  fitdf = 2
)


# Residual QQ-plot.
qqnorm(
  arma_residuals,
  main = "QQ-Plot of ARMA(1,1) Residuals"
)

qqline(arma_residuals)


# 10. Short-term forecasting ----------------------------------

forecast_arma <- forecast(
  arma_11,
  h = 2,
  level = 95
)

print(forecast_arma)

plot(
  forecast_arma,
  main = "Two-Month Forecast of Log-Differenced Industrial Production",
  xlab = "Time",
  ylab = "Monthly log difference"
)


# 11. Joint prediction region ---------------------------------

# Extract estimated parameters.
phi <- as.numeric(arma_11$coef["ar1"])
theta <- as.numeric(arma_11$coef["ma1"])
sigma2 <- arma_11$sigma2


# Variance-covariance matrix of the two-step forecast errors.
d <- 1 + phi + theta

Sigma <- matrix(
  c(
    sigma2,
    d * sigma2,
    d * sigma2,
    (1 + d^2) * sigma2
  ),
  nrow = 2,
  byrow = TRUE
)


# Point forecasts.
pred <- predict(
  arma_11,
  n.ahead = 2,
  se.fit = TRUE
)


# 95% joint prediction ellipse.
prediction_ellipse <- ellipse(
  Sigma,
  centre = pred$pred,
  level = 0.95,
  npoints = 1000
)


plot(
  prediction_ellipse,
  xlab = expression(hat(Z)[T+1]),
  ylab = expression(hat(Z)[T+2]),
  main = "95% Joint Prediction Region"
)

points(
  pred$pred[1],
  pred$pred[2],
  pch = 19
)


# 12. Forecast visualisation ----------------------------------

last_date <- max(data$date)

forecast_data <- data.frame(
  date = seq(
    last_date %m+% months(1),
    by = "1 month",
    length.out = 2
  ),
  forecast = as.numeric(pred$pred),
  lower = as.numeric(pred$pred - 1.96 * pred$se),
  upper = as.numeric(pred$pred + 1.96 * pred$se)
)


historical_data <- data %>%
  select(date, log_diff) %>%
  drop_na()


ggplot(historical_data, aes(x = date, y = log_diff)) +
  geom_line(linewidth = 0.5) +
  geom_ribbon(
    data = forecast_data,
    aes(
      x = date,
      ymin = lower,
      ymax = upper
    ),
    inherit.aes = FALSE,
    alpha = 0.2
  ) +
  geom_line(
    data = forecast_data,
    aes(x = date, y = forecast),
    inherit.aes = FALSE,
    linetype = "dashed",
    linewidth = 0.8
  ) +
  geom_point(
    data = forecast_data,
    aes(x = date, y = forecast),
    inherit.aes = FALSE,
    size = 2
  ) +
  labs(
    title = "Short-Term Forecast of Industrial Production Growth",
    subtitle = "ARMA(1,1) forecasts with 95% prediction intervals",
    x = NULL,
    y = "Monthly log difference"
  ) +
  theme_minimal(base_size = 13)
