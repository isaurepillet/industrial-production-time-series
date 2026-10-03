# Industrial Production Time Series Analysis

**Time-series modelling and forecasting of French industrial production using R**

This project analyses the monthly French industrial production index for the manufacture of food products, beverages and tobacco products from January 1990 to March 2025.

The analysis was conducted as part of the Linear Time Series course at ENSAE Paris.

## Objectives

The project aims to characterise the dynamics of the industrial production series, determine an appropriate time-series specification and produce short-term forecasts with associated measures of uncertainty.

## Methodology

The empirical analysis includes:

- logarithmic transformation and first differencing;
- seasonality testing;
- Augmented Dickey-Fuller (ADF) and KPSS stationarity tests;
- autocorrelation and partial autocorrelation analysis;
- ARMA model estimation and selection using AIC and BIC;
- residual diagnostics using the Ljung-Box test;
- short-term forecasting and prediction intervals;
- construction of a joint confidence region for forecast errors.

## Results

The original log-transformed series is found to be non-stationary, while its first difference is stationary according to both ADF and KPSS tests.

Several ARMA specifications are compared. An ARMA(1,1) model is selected based on information criteria and residual diagnostics. The estimated model is then used to produce short-term forecasts and quantify forecast uncertainty.

## Data

The analysis uses the seasonally and working-day adjusted (SA-WDA) French
industrial production index for the manufacture of food products, beverages
and tobacco products (NAF Rev. 2, A17, item C1), published by INSEE.

- **Source:** INSEE
- **Series ID:** 010768267
- **Frequency:** Monthly
- **Period analysed:** January 1990 – March 2025
- **Base:** 100 in 2021

[INSEE series](https://www.insee.fr/en/statistiques/serie/010768267)

## Tools

The analysis was conducted in **R**, using packages including:

- `tidyverse`
- `forecast`
- `tseries`
- `urca`
- `ggplot2`
- `ellipse`

## Repository structure

- `code/` — R code used for data preparation, estimation and forecasting
- `data/` — input data
- `figures/` — main figures produced by the analysis
- `report/` — full project report

## Authors

Camille Legrée-Haghbarth and Isaure Pillet  
ENSAE Paris — Linear Time Series
