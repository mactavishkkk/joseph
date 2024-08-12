library(rstanarm)
library(lubridate)
library(forecast)
library(rstan)
library(zoo)

db_landsat_csv <- ""
db_landsat_csv_clima <- ""
db_landsat_sat <- read.csv(db_landsat_csv)
db_landsat_clima <- read.csv(db_landsat_csv_clima)

db_landsat<- cbind(db_landsat_sat[,1:2], db_landsat_clima[,3:11] )

db_landsat$Date <- ymd(db_landsat$data)


coord_ref<-read.csv("../python/docs/coordenadas_usar.csv", header = TRUE)
coords_ref<-coord_ref[,2:3]

save_path <- "./models/"

all_predictions <- list()
models <- list()

save_partial_results <- function(iteration, predictions, path) {
  saveRDS(predictions, file = paste0(path, "partial_predictions_", iteration, ".rds"))
}

d=0
data_list <- list()
models <- list()
i=1
for (i in 1:nrow(coords_ref)){
  x_value<-coords_ref$x[i]
  y_value<-coords_ref$y[i]
  

  coord_data<-db_landsat[db_landsat$x==x_value & db_landsat$y == y_value,]
  coord_data$Date <- as.Date(coord_data$Date)
  
  ndvi_values <- coord_data$ndvi
  ndwi_values <- coord_data$ndwi
  hsi_values <- coord_data$hsi
  mh_temp_max_values<- na.approx(coord_data$MHTEMPMAX.media.harmonica.temperatura.maxima.C, rule = 2)
  mh_temp_min_values<- na.approx(coord_data$MHTEMPMIN.media.harmonica.temperatura.minima.C.., rule = 2)
  soma_chuva_values<- na.approx(coord_data$SUMCHUVA.soma.chuva.mm.., rule = 2)
  mh_evap_tranp_values<- na.approx(coord_data$MHEVAPOTRANSPIRACAO.media.harmonica.soma.evapotranspiracao.mm.., rule = 2)
  
  
  if (length(ndvi_values) == length(ndwi_values) &&
      length(ndvi_values) == length(hsi_values) &&
      length(ndvi_values) == length(mh_evap_tranp) &&
      length(ndvi_values) == length(mh_temp_max) &&
      length(ndvi_values) == length(mh_temp_min) &&
      length(ndvi_values) == length(soma_chuva)) {
    
  
    data_frame <- data.frame(
      time = seq_along(ndvi_values) * 12, 
      ndvi = ndvi_values,
      ndwi = ndwi_values,
      hsi = hsi_values,
      mh_temp_max =mh_temp_max_value,
      mh_temp_min =mh_temp_min_value,
      mh_evap_tranp =   mh_evap_tranp_values,
      soma_chuva = soma_chuva_values
    )
    
  
  } else {
    stop("Os vetores têm comprimentos diferentes.")
  }
  
  N_pred <- 2
  time_pred <- max(data_frame$time) + 1:N_pred

  stan_model <- "
  data {
    int<lower=0> N;  // Número de observações
    int<lower=0> N_pred;  // Número de previsões
    vector[N] time;  // Vetor de tempo (em meses)
    
    // Dados para os índices
    vector[N] ndvi;
    vector[N] ndwi;
    vector[N] hsi;
    vector[N] mh_temp_max;
    vector[N] mh_temp_min;
    vector[N] mh_evap_tranp;
    vector[N] soma_chuva;
    
    // Previsão para o tempo futuro
    vector[N_pred] time_pred;
  }
  parameters {
    // Parâmetros para NDVI
    real alpha_ndvi;
    real beta_ndvi;
    real<lower=0> sigma_ndvi;
    
    // Parâmetros para NDWI
    real alpha_ndwi;
    real beta_ndwi;
    real<lower=0> sigma_ndwi;
    
    // Parâmetros para HSI
    real alpha_hsi;
    real beta_hsi;
    real<lower=0> sigma_hsi;
    
    // Parâmetros para Temperatura Máxima
    real alpha_mh_temp_max;
    real beta_mh_temp_max;
    real<lower=0> sigma_mh_temp_max;
    
    // Parâmetros para Temperatura Mínima
    real alpha_mh_temp_min;
    real beta_mh_temp_min;
    real<lower=0> sigma_mh_temp_min;
    
    // Parâmetros para Evapotranspiração
    real alpha_mh_evap_tranp;
    real beta_mh_evap_tranp;
    real<lower=0> sigma_mh_evap_tranp;
    
    // Parâmetros para Soma da Chuva
    real alpha_soma_chuva;
    real beta_soma_chuva;
    real<lower=0> sigma_soma_chuva;
  }
  model {
    // Priors
    alpha_ndvi ~ normal(0, 10);
    beta_ndvi ~ normal(0, 1);
    sigma_ndvi ~ normal(0, 1);
    
    alpha_ndwi ~ normal(0, 10);
    beta_ndwi ~ normal(0, 1);
    sigma_ndwi ~ normal(0, 1);
    
    alpha_hsi ~ normal(0, 10);
    beta_hsi ~ normal(0, 1);
    sigma_hsi ~ normal(0, 1);
    
    alpha_mh_temp_max ~ normal(0, 10);
    beta_mh_temp_max ~ normal(0, 1);
    sigma_mh_temp_max ~ normal(0, 1);
    
    alpha_mh_temp_min ~ normal(0, 10);
    beta_mh_temp_min ~ normal(0, 1);
    sigma_mh_temp_min ~ normal(0, 1);
    
    alpha_mh_evap_tranp ~ normal(0, 10);
    beta_mh_evap_tranp ~ normal(0, 1);
    sigma_mh_evap_tranp ~ normal(0, 1);
    
    alpha_soma_chuva ~ normal(0, 10);
    beta_soma_chuva ~ normal(0, 1);
    sigma_soma_chuva ~ normal(0, 1);
    
    // Likelihood para NDVI
    ndvi ~ normal(alpha_ndvi + beta_ndvi * time, sigma_ndvi);
    
    // Likelihood para NDWI
    ndwi ~ normal(alpha_ndwi + beta_ndwi * time, sigma_ndwi);
    
    // Likelihood para HSI
    hsi ~ normal(alpha_hsi + beta_hsi * time, sigma_hsi);
    
    // Likelihood para Temperatura Máxima
    mh_temp_max ~ normal(alpha_mh_temp_max + beta_mh_temp_max * time, sigma_mh_temp_max);
    
    // Likelihood para Temperatura Mínima
    mh_temp_min ~ normal(alpha_mh_temp_min + beta_mh_temp_min * time, sigma_mh_temp_min);
    
    // Likelihood para Evapotranspiração
    mh_evap_tranp ~ normal(alpha_mh_evap_tranp + beta_mh_evap_tranp * time, sigma_mh_evap_tranp);
    
    // Likelihood para Soma da Chuva
    soma_chuva ~ normal(alpha_soma_chuva + beta_soma_chuva * time, sigma_soma_chuva);
  }
  generated quantities {
    vector[N_pred] ndvi_pred;
    vector[N_pred] ndwi_pred;
    vector[N_pred] hsi_pred;
    vector[N_pred] mh_temp_max_pred;
    vector[N_pred] mh_temp_min_pred;
    vector[N_pred] mh_evap_tranp_pred;
    vector[N_pred] soma_chuva_pred;
    
    for (i in 1:N_pred) {
      ndvi_pred[i] = normal_rng(alpha_ndvi + beta_ndvi * time_pred[i], sigma_ndvi);
      ndwi_pred[i] = normal_rng(alpha_ndwi + beta_ndwi * time_pred[i], sigma_ndwi);
      hsi_pred[i] = normal_rng(alpha_hsi + beta_hsi * time_pred[i], sigma_hsi);
      mh_temp_max_pred[i] = normal_rng(alpha_mh_temp_max + beta_mh_temp_max * time_pred[i], sigma_mh_temp_max);
      mh_temp_min_pred[i] = normal_rng(alpha_mh_temp_min + beta_mh_temp_min * time_pred[i], sigma_mh_temp_min);
      mh_evap_tranp_pred[i] = normal_rng(alpha_mh_evap_tranp + beta_mh_evap_tranp * time_pred[i], sigma_mh_evap_tranp);
      soma_chuva_pred[i] = normal_rng(alpha_soma_chuva + beta_soma_chuva * time_pred[i], sigma_soma_chuva);
    }
  }
"

  N_pred <- 2
  time_pred <- max(data_frame$time) + 1:N_pred
  
  print("Modelando")

  stan_fit <- stan(
    model_code = stan_model,
    data = list(
      N = nrow(data_frame),
      N_pred = N_pred,
      time = data_frame$time,
      ndvi = data_frame$ndvi,
      ndwi = data_frame$ndwi,
      hsi = data_frame$hsi,
      mh_temp_max = data_frame$mh_temp_max,
      mh_temp_min = data_frame$mh_temp_min,
      mh_evap_tranp = data_frame$mh_evap_tranp,
      soma_chuva = data_frame$soma_chuva,
      time_pred = time_pred
    ),
    chains = 6,   
    iter = 2000,  
    warmup = 1000,
    seed = 123
  )

  predictions <- extract(stan_fit, pars = c("ndvi_pred", "ndwi_pred", "hsi_pred","mh_temp_max_pred", "mh_temp_min_pred", "mh_evap_tranp_pred", "soma_chuva_pred"))
  

  ndvi_pred_means <- apply(predictions$ndvi_pred, 2, mean)
  ndwi_pred_means <- apply(predictions$ndwi_pred, 2, mean)
  hsi_pred_means <- apply(predictions$hsi_pred, 2, mean)
  mhtempmax_pred_means <- apply(predictions$mh_temp_max_pred, 2, mean)
  mhtempmin_pred_means <- apply(predictions$mh_temp_min_pred, 2, mean)
  mhevatransp_pred_means <- apply(predictions$mh_evap_tranp_pred, 2, mean)
  somachuva_pred_means <- apply(predictions$soma_chuva_pred, 2, mean)
  
  models[[paste0("coord_", i)]] <- list(model = stan_fit, 
                                        ndvi_prediction = ndvi_pred_means,
                                        ndwi_prediction = ndwi_pred_means,
                                        hsi_prediction = hsi_pred_means,
                                        mh_TMAX_prediction = mhtempmax_pred_means,
                                        mh_TMIN_prediction = mhtempmin_pred_means,
                                        mh_EvTRANSP_prediction = mhevatransp_pred_means,
                                        sum_chuva = somachuva_pred_means 
  )
  
  all_predictions[[paste0("coord_", i)]] <- list(ndvi_pred_means, ndwi_pred_means, hsi_pred_means, mhtempmax_pred_means, mhtempmin_pred_means, mhevatransp_pred_means, somachuva_pred_means 
  )

  d=d+1
  

  if (d %% 100 == 0) {
    save_partial_results(i, all_predictions, save_path)
    all_predictions <- list()  # Limpar a lista para as próximas iterações
    d=1
  }
  print(i)
  print(d)
}

# Salvar os resultados finais após o loop
save_partial_results("final", all_predictions, save_path)

# Salvar todos os modelos em um único arquivo
saveRDS(models, file = paste0(save_path, "all_models.rds"))

#### 3######
ndvi_pred = sapply(models, function(model) model$ndvi_prediction)
ndwi_pred = sapply(models, function(model) model$ndwi_prediction)
hsi_pred = sapply(models, function(model) model$hsi_prediction)

mh_TMAX_pred = sapply(models, function(model) model$)
mh_TMIN_pred = sapply(models, function(model) model$hsi_prediction)
mh_EVAPO_pred = sapply(models, function(model) model$hsi_prediction)
soma_chuva_pred = sapply(models, function(model) model$hsi_prediction)

ndwi_df <-t(data.frame(
  row.names = c("20241012_ndwi", "20241112_ndwi"),
  ndwi_pred = ndwi_pred
))

ndvi_df <-t(data.frame(
  row.names = c("20241012_ndvi", "20241112_ndvi"),
  ndvi_pred = ndvi_pred
))

hsi_df <-t(data.frame(
  row.names = c("20241012_hsi", "20241112_hsi"),
  hsi_pred = hsi_pred
))


predictions_df <-cbind(ndwi_df,hsi_df,ndvi_df,coords_ref[1:125,])
head(predictions_df)
write.csv(predictions_df,"../python/docs/125outubro_novembro_.csv" )
























# ... (rest of your code for spatial join and mapping)

library(ggplot2)
library(sf)
library(RColorBrewer)

# Assuming 'joined_data' is your data frame with predictions and spatial data

ggplot(joined_data, aes(x = geometry, fill = ndwi_predictions)) +
  geom_sf() +
  scale_fill_gradient(low = "green", high = "brown", name = "NDWI") +
  labs(title = "NDWI Predictions (Two Months Ahead)")

ggplot(joined_data, aes(x = geometry, fill = hsi_predictions)) +
  geom_sf() +
  scale_fill_gradient(low = "green", high = "red", name = "HSI") +
  labs(title = "HSI Predictions (Two Months Ahead)")







######
install.packages("rasterVis")
library(rasterVis)

# Convert the data frames to matrices
ndwi_mat <- as.matrix(predictions_df[, c("20241012_ndwi", "20241112_ndwi")])
ndvi_mat <- as.matrix(predictions_df[, c("20241012_ndvi", "20241112_ndvi")])
hsi_mat <- as.matrix(predictions_df[, c("20241012_hsi", "20241112_hsi")])

# Create a color ramp
ramp <- colorRampPalette(c("green", "yellow", "red"))

# Create the graphs
par(mfrow = c(1, 3))

# NDWI
image(ndwi_mat, main = "NDWI", col = ramp(100))
legend("topright", legend = c("20241012", "20241112"), fill = ramp(100), cex = 0.8)

# NDVI
image(ndvi_mat, main = "NDVI", col = ramp(100))
legend("topright", legend = c("20241012", "20241112"), fill = ramp(100), cex = 0.8)

# HSI
image(hsi_mat, main = "HSI", col = ramp(100))
legend("topright", legend = c("20241012", "20241112"), fill = ramp(100), cex = 0.8)

# Close the plot
par(mfrow = c(1, 1))


