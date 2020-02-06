import createPersistedState from 'vuex-persistedstate'

export default function getStorePlugins() {
  return [
    createPersistedState({
      key: 'FleetYards-Fleetview',
      paths: [
        'storeVersion',
        'details',
        'fleetchart',
        'fleetchartScale',
        'grouping',
        'fleetchartGrouping',
      ],
    }),
  ]
}
