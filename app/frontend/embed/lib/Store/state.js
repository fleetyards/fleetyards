export default () => {
  let config = {}
  // eslint-disable-next-line camelcase
  if (typeof fleetyards_config !== 'undefined') {
    // eslint-disable-next-line no-undef
    config = fleetyards_config()
  } else {
    config = window.FleetYardsFleetchartConfig || {}
  }

  const scale = Math.max(config.fleetchartScale || 0, 10)

  return {
    details: config.details || true,
    fleetchart: config.fleetchart || false,
    fleetchartGrouping: config.fleetchartGrouped || false,
    fleetchartScale: scale,
    grouping: config.grouped || true,
    locale: 'en-US',
    storeVersion: null,
  }
}
