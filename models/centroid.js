'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Centroid extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }
  }
  Centroid.init({
    state: DataTypes.STRING,
    county: DataTypes.STRING,
    latitude: DataTypes.STRING,
    longitude: DataTypes.STRING,
  }, {
    sequelize,
    modelName: 'Centroid',
  });
  return Centroid;
};