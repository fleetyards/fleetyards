import 'stylesheets/embed'
import 'babel-polyfill'
import Vue from 'vue'
import VTooltip from 'v-tooltip'
import FleetyardsView from 'embed/FleetyardsView'
import store from 'embed/lib/Store'
import 'frontend/lib/ApiClient'
import 'frontend/lib/LazyLoad'

const d = document
const styles = d.createElement('link')
styles.href = `${process.env.FRONTEND_HOST}/embed-styles.css#${+new Date()}`
styles.rel = 'stylesheet'
styles.type = 'text/css';
(d.head || d.body).appendChild(styles)

const fonts = d.createElement('link')
fonts.href = '//fonts.googleapis.com/css?family=Open+Sans:400,700|Orbitron:400,500,700,900'
fonts.rel = 'stylesheet'
fonts.media = 'all';
(d.head || d.body).appendChild(fonts)

Vue.config.productionTip = false

VTooltip.enabled = window.innerWidth > 768
Vue.use(VTooltip, {
  defaultContainer: '#fleetyards-view',
})

// eslint-disable-next-line no-undef
const config = fleetyards_config()

setTimeout(() => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#fleetyards-view',
    store,
    data: {
      ships: config.ships || [],
      groupedButton: config.groupedButton || false,
      fleetchartSlider: config.fleetchartSlider || false,
      frontendHost: process.env.FRONTEND_HOST,
    },
    render: h => h(FleetyardsView),
  })
}, 1000)
