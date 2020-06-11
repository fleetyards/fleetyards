process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const TerserPlugin = require('terser-webpack-plugin')
const environment = require('./environment')

environment.config.optimization.minimizer.forEach(minimizer => {
  if (minimizer instanceof TerserPlugin) {
    // eslint-disable-next-line no-param-reassign
    minimizer.options.parallel = false
  }
})

module.exports = environment.toWebpackConfig()
