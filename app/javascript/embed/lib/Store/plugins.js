import createPersistedState from 'vuex-persistedstate'

export default function getStorePlugins() {
  return [createPersistedState({
    key: 'FleetYards-Fleetview',
    paths: [
      'details',
      'fleetchart',
      'scale',
      'grouping',
      'fleetchartGrouping',
    ],
  })]
}
