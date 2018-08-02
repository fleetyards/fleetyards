process.env.NODE_ENV = process.env.NODE_ENV || 'production'
process.env.API_URL = process.env.API_URL || 'https://api.fleetyards.net/v1'
process.env.STORE_VERSION = process.env.STORE_VERSION || 4
process.env.RAVEN_DSN = process.env.RAVEN_DSN || 'https://8f22c2e65f80462580a3d65b5c907d21@sentry.io/186028'
process.env.CABLE_URL = process.env.CABLE_URL || 'wss://api.fleetyards.net/cable'

const environment = require('./environment')

module.exports = environment.toWebpackConfig()
