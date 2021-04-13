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
    locale: 'en-US',
    storeVersion: null,
    details: config.details || true,
    fleetchart: config.fleetchart || false,
    fleetchartScale: scale,
    grouping: config.grouped || true,
    fleetchartGrouping: config.fleetchartGrouped || false,
  }
}
