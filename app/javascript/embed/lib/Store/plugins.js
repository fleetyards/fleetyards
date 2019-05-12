import createPersistedState from 'vuex-persistedstate'

export default function getStorePlugins() {
  return [createPersistedState({
    key: 'FleetYards-Fleetview',
    paths: [
      'details',
      'fleetchart',
      'grouping',
      'fleetchartGrouping',
    ],
  })]
}
