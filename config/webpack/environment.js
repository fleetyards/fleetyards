const { environment } = require('@rails/webpacker')
const { VueLoaderPlugin } = require('vue-loader')
const typescript = require('./loaders/typescript')
const vue = require('./loaders/vue')

environment.splitChunks()

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.prepend('vue', vue)
environment.loaders.prepend('typescript', typescript)
module.exports = environment
