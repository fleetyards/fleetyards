process.env.NODE_ENV = process.env.NODE_ENV || 'development'
process.env.FRONTEND_ENDPOINT = 'http://localhost:3000'

const environment = require('./environment')

module.exports = environment.toWebpackConfig()
