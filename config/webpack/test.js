process.env.NODE_ENV = process.env.NODE_ENV || 'development'
process.env.API_URL = 'http://api.fleetyards.test/v1'
process.env.STORE_VERSION = 4

const environment = require('./environment')

module.exports = environment.toWebpackConfig()
