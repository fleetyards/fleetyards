process.env.NODE_ENV = process.env.NODE_ENV || 'production'
process.env.FRONTEND_ENDPOINT = process.env.FRONTEND_ENDPOINT || 'https://fleetyards.net'

const environment = require('./environment')

module.exports = environment.toWebpackConfig()
