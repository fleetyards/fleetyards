process.env.NODE_ENV = process.env.NODE_ENV || 'development'
process.env.API_URL = 'http://localhost:3000/v1'
process.env.FRONTEND_HOST = 'http://localhost:3000'
process.env.STORE_VERSION = 7

const environment = require('./environment')

module.exports = environment.toWebpackConfig()
