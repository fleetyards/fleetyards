process.env.NODE_ENV = process.env.NODE_ENV || 'production'
process.env.FRONTEND_ENDPOINT = process.env.FRONTEND_ENDPOINT || 'http://localhost:8270'

const environment = require('./environment')

module.exports = environment.toWebpackConfig()
