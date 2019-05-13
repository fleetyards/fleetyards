export default () => {
  // eslint-disable-next-line no-undef
  const config = fleetyards_config()
  const scale = Math.max(config.fleetchartScale, 10)

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
