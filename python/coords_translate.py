import pandas as pd
import numpy as np

caminho_do_arquivo = './docs/timeline_2014_2024.csv'

df = pd.read_csv(caminho_do_arquivo)
df = df.rename(columns={'x': 'Latitude', 'y': 'Longitude'})

df['MHTEMPMAX(media-harmonica-temperatura-maxima(C))'] = np.nan
df['MHTEMPMIN(media-harmonica-temperatura-minima(C))'] = np.nan
df['SUMCHUVA(soma-chuva(mm))'] = np.nan
df['MHEVAPOTRANSPIRACAO(media-harmonica-soma-evapotranspiracao(mm))'] = np.nan

def format_coordinates(lat_str, lon_str):
    lat_str = lat_str.strip()
    lon_str = lon_str.strip()
    
    lat = float(lat_str) / 100000.0
    lat_formatted = f"{-lat:.5f}"
    
    lon = float(lon_str) / 10000.0
    lon_formatted = f"{lon:.5f}"

    return lat_formatted, lon_formatted

df[['Latitude', 'Longitude']] = df.apply(
    lambda row: pd.Series(format_coordinates(str(row['Latitude']), str(row['Longitude']))),
    axis=1
)

def format_date(date_str):
    date_str = str(date_str).split('.')[0]  
    return f"{date_str[:4]}/{date_str[4:6]}/{date_str[6:]}"


df['data'] = df['data'].astype(str).apply(format_date)

if 'Unnamed: 7' in df.columns:
    df = df.drop(columns=['Unnamed: 7'])

print(df.head())

caminho_do_novo_arquivo = './docs/joseph_coords.csv'
df.to_csv(caminho_do_novo_arquivo, index=False)
