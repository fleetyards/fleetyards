const { resolve } = require('path')

const webpackerConfig = require('@rails/webpacker/package/config')

module.exports = ({ config }) => {
  config.module.rules.push({
    test: /\.vue$/,
    loader: 'storybook-addon-vue-info/loader',
    enforce: 'post',
  })
  config.module.rules.push({
    test: /\.scss$/,
    loaders: ['style-loader', 'css-loader', 'sass-loader'],
    include: resolve(__dirname, '../'),
  })

  config.resolve.modules.unshift(resolve(webpackerConfig.source_path))

  return config
}
