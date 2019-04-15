process.env.NODE_ENV = process.env.NODE_ENV || 'development'
process.env.FRONTEND_ENDPOINT = process.env.FRONTEND_ENDPOINT || 'http://fleetyards.test'

const environment = require('./environment')

module.exports = environment.toWebpackConfig()
