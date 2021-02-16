const { webpackConfig, merge } = require('@rails/webpacker')

const vueConfig = require('./rules/vue')

module.exports = merge(webpackConfig, vueConfig)
