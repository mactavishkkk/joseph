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
}

module.exports = Dataset;