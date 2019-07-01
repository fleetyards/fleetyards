
const getByKey = function getByKey(key) {
  return (window.DATA_PREFILL || {})[key]
}

const cleanData = function cleanData(key) {
  if (!window.DATA_PREFILL || !window.DATA_PREFILL[key]) {
    return
  }
  window.DATA_PREFILL[key] = null
}

const prefetch = function prefetch(key) {
  const json = getByKey(key)
  cleanData(key)

  if (!json) {
    return null
  }

  const element = JSON.parse(json)
  if (Array.isArray(element)) {
    return element.map(item => JSON.parse(item))
  }
  return element
}

export default {
  install(Vue) {
    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$prefetch = prefetch
  },
}
