const pool = require('../config/config');

class Dataset {
  static async getAll(page = 1, limit = 10) {
    const offset = (page - 1) * limit;
    try {
      const result = await pool.query(
        'SELECT * FROM public.dataset_past_future ORDER BY id ASC LIMIT $1 OFFSET $2',
        [limit, offset]
      );
      return {
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
        totalRecords: result.rowCount,
        data: result.rows,
      };
    } catch (error) {
      throw new Error('Erro ao buscar dados: ' + error.message);
    }
  }

  static async getAverageRainfallByYear() {
    const query = `
      SELECT 
        EXTRACT(YEAR FROM TO_DATE("data", 'YYYY-MM-DD')) AS ano, 
        AVG(chuva) AS media
      FROM 
        public.dataset_past_future
      WHERE 
        EXTRACT(YEAR FROM TO_DATE("data", 'YYYY-MM-DD')) <= 2020
      GROUP BY 
        ano
      ORDER BY 
        ano;
    `;
    try {
      const result = await pool.query(query);
      return result.rows;
    } catch (error) {
      throw new Error('Erro ao buscar a média de chuva por ano: ' + error.message);
    }
  }

  static async getAverageMetricsByYear() {
    const query = `
      SELECT 
        EXTRACT(YEAR FROM TO_DATE("data", 'YYYY-MM-DD')) AS ano, 
        AVG(ndvi) AS avg_ndvi,
        AVG(ndwi) AS avg_ndwi,
        AVG(hsi) AS avg_hsi,
        AVG(temp_max) AS avg_temp_max,
        AVG(temp_min) AS avg_temp_min,
        AVG(chuva) AS avg_chuva,
        AVG(evapo) AS avg_evapo
      FROM 
        public.dataset_past_future
      WHERE 
        EXTRACT(YEAR FROM TO_DATE("data", 'YYYY-MM-DD')) <= 2020
      GROUP BY 
        ano
      ORDER BY 
        ano;
    `;
    try {
      const result = await pool.query(query);

      const metricsByYear = {};
      result.rows.forEach(row => {
        metricsByYear[row.ano] = {
          ndvi: parseFloat(row.avg_ndvi),
          ndwi: parseFloat(row.avg_ndwi),
          hsi: parseFloat(row.avg_hsi),
          temp_max: parseFloat(row.avg_temp_max),
          temp_min: parseFloat(row.avg_temp_min),
          soma_chuva: parseFloat(row.avg_chuva),
          evapotrans: parseFloat(row.avg_evapo)
        };
      });

      return metricsByYear;
    } catch (error) {
      throw new Error('Erro ao buscar as médias dos dados por ano: ' + error.message);
    }
  }
}

module.exports = Dataset;
