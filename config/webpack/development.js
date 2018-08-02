process.env.NODE_ENV = process.env.NODE_ENV || 'development'
process.env.API_URL = process.env.API_URL || 'http://api.fleetyards.test/v1'
process.env.STORE_VERSION = process.env.STORE_VERSION || 4
process.env.CABLE_URL = process.env.CABLE_URL || 'ws://api.fleetyards.test/cable'

const environment = require('./environment')

module.exports = environment.toWebpackConfig()
