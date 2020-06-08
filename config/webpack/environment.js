const { environment } = require('@rails/webpacker')
const { VueLoaderPlugin } = require('vue-loader')
const vue = require('./loaders/vue')

environment.splitChunks(config => ({
  ...config,
  optimization: {
    ...config.optimization,
    splitChunks: {
      ...config.optimization.splitChunks,
      minSize: 10000,
      maxAsyncRequests: 6,
      maxInitialRequests: 4,
    },
  },
}))

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.prepend('vue', vue)
module.exports = environment
