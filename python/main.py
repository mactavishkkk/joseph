import pandas as pd
import numpy as np
import openmeteo_requests
import requests_cache
from retry_requests import retry
from scipy.stats import hmean
import time
from datetime import datetime, timedelta

def setup_openmeteo_client():
    cache_session = requests_cache.CachedSession('.cache', expire_after=-1)
    retry_session = retry(cache_session, retries=5, backoff_factor=0.2)
    return openmeteo_requests.Client(session=retry_session)

def get_meteo_data(openmeteo_client, latitude, longitude, start_date, end_date):
    url = "https://archive-api.open-meteo.com/v1/archive"
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "start_date": start_date,
        "end_date": end_date,
        "daily": ["temperature_2m_max", "temperature_2m_min", "rain_sum", "et0_fao_evapotranspiration"]
    }
    responses = openmeteo_client.weather_api(url, params=params)
    response = responses[0]
    
    daily = response.Daily()
    daily_data = {
        "date": pd.date_range(
            start=pd.to_datetime(daily.Time(), unit="s", utc=True),
            end=pd.to_datetime(daily.TimeEnd(), unit="s", utc=True),
            freq=pd.Timedelta(seconds=daily.Interval()),
            inclusive="left"
        ),
        "temperature_2m_max": daily.Variables(0).ValuesAsNumpy(),
        "temperature_2m_min": daily.Variables(1).ValuesAsNumpy(),
        "rain_sum": daily.Variables(2).ValuesAsNumpy(),
        "et0_fao_evapotranspiration": daily.Variables(3).ValuesAsNumpy()
    }
    return pd.DataFrame(data=daily_data)

caminho_do_arquivo = '/home/mac/Downloads/gic/ndwi/joseph_coords.csv'

df = pd.read_csv(caminho_do_arquivo)

openmeteo_client = setup_openmeteo_client()

def harmonic_mean(series):
    return hmean(series) if all(series > 0) else np.nan

df['data'] = pd.to_datetime(df['data'], errors='coerce', infer_datetime_format=True)

inicio = time.time()
linha_inicial = 0

for index, row in df.iterrows():
    if index < linha_inicial:
        continue

    time.sleep(1.5)

    latitude = row['Latitude']
    longitude = row['Longitude']
    end_date = row['data']
    
    if pd.isnull(end_date):
        print(f"Pula a linha {index + 1} devido a data inválida.")
        continue
    
    start_date = (end_date - pd.DateOffset(months=4)).strftime('%Y-%m-%d')
    end_date = end_date.strftime('%Y-%m-%d')
    
    daily_dataframe = get_meteo_data(openmeteo_client, latitude, longitude, start_date, end_date)

    somas = daily_dataframe[['temperature_2m_max', 'temperature_2m_min', 'rain_sum', 'et0_fao_evapotranspiration']].sum()

    media_harmonicas = {
        "temperature_2m_max": harmonic_mean(daily_dataframe['temperature_2m_max']),
        "temperature_2m_min": harmonic_mean(daily_dataframe['temperature_2m_min']),
        "et0_fao_evapotranspiration": harmonic_mean(daily_dataframe['et0_fao_evapotranspiration'])
    }

    df.loc[index, 'MHTEMPMAX(media-harmonica-temperatura-maxima(C))'] = media_harmonicas['temperature_2m_max']
    df.loc[index, 'MHTEMPMIN(media-harmonica-temperatura-minima(C))'] = media_harmonicas['temperature_2m_min']
    df.loc[index, 'SUMCHUVA(soma-chuva(mm))'] = somas['rain_sum']
    df.loc[index, 'MHEVAPOTRANSPIRACAO(media-harmonica-soma-evapotranspiracao(mm))'] = media_harmonicas['et0_fao_evapotranspiration']

    caminho_do_novo_arquivo = '/home/mac/Downloads/gic/ndwi/joseph_dataframe.csv'
    df.to_csv(caminho_do_novo_arquivo, index=False)

    fim = time.time()
    tempo_gasto = fim - inicio

    print(f"Processando linha {index + 1} | Latitude: {latitude} | Tempo gasto até agora: {tempo_gasto:.4f} segundos")

fim = time.time()
tempo_gasto = fim - inicio

print(f"Processamento concluído! | Tempo total gasto: {tempo_gasto:.4f} segundos")
