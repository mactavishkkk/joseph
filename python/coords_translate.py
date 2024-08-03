import pandas as pd
import numpy as np

# Substitua 'caminho/para/seu/arquivo.csv' pelo caminho real do seu arquivo CSV
caminho_do_arquivo = '/home/mac/Downloads/gic/ndwi/2023_10_12_1.csv'

# Lê o arquivo CSV
df = pd.read_csv(caminho_do_arquivo)

df['MHTEMPMAX(media-harmonica-temperatura-maxima(C))'] = np.nan
df['MHTEMPMIN(media-harmonica-temperatura-minima(C))'] = np.nan
df['SUMCHUVA(soma-chuva(mm))'] = np.nan
df['MHPRECIPITACAO(media-harmonica-soma-precipitacao(mm))'] = np.nan
df['MHEVAPOTRANSPIRACAO(media-harmonica-soma-evapotranspiracao(mm))'] = np.nan

# Função para alterar o formato das coordenadas usando strings
def format_coordinates(lat_str, lon_str):
    # Remove espaços e formata as strings
    lat_str = lat_str.strip()
    lon_str = lon_str.strip()

    # Converte latitude
    lat = float(lat_str) / 100000.0
    lat_formatted = f"{lat:.5f}"

    # Converte longitude e garante que é negativa
    lon = float(lon_str) / 10000.0
    lon_formatted = f"-{lon:.5f}"

    return lat_formatted, lon_formatted

# Aplica a formatação às coordenadas
df[['Latitude', 'Longitude']] = df.apply(
    lambda row: pd.Series(format_coordinates(str(row['Latitude']), str(row['Longitude']))),
    axis=1
)

# Exibe o DataFrame atualizado
print(df.head())

# Salva o DataFrame atualizado em um novo arquivo CSV
caminho_do_novo_arquivo = '/home/mac/Downloads/gic/ndwi/joseph_coords.csv'
df.to_csv(caminho_do_novo_arquivo, index=False)
