const { webpackConfig, merge } = require('@rails/webpacker')
const vueConfig = require('./rules/vue')
const customConfig = require('./custom')

module.exports = merge(vueConfig, webpackConfig, customConfig)
