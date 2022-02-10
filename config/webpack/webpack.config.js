const { webpackConfig: baseWebpackConfig, merge } = require('shakapacker')

const webpack = require('webpack')
const WorkboxPlugin = require('workbox-webpack-plugin')
const { VueLoaderPlugin } = require('vue-loader')
const ForkTSCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin')

const overrides = {
  module: {
    rules: [
      {
        test: /\.vue$/,
        loader: 'vue-loader',
      },
    ],
  },
  plugins: [
    new ForkTSCheckerWebpackPlugin(),
    new VueLoaderPlugin(),
    new WorkboxPlugin.GenerateSW({
      exclude: [/admin/, /embed/, /hangar-guide\/.*\.gif/],
    }),
    new webpack.ProvidePlugin({
      process: 'process/browser',
    }),
  ],
  resolve: {
    extensions: ['.css', '.vue'],
    alias: {
      vue: 'vue/dist/vue.esm',
    },
  },
}

module.exports = merge(overrides, baseWebpackConfig)
