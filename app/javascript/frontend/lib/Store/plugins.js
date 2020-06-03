import createPersistedState from 'vuex-persistedstate'

export default function getStorePlugins() {
  return [
    createPersistedState({
      key: 'FleetYards',
      paths: [
        'route',
        'storeVersion',
        'filters',
        'filtersVisible',
        'app.navSlim',
        'session.authToken',
        'session.currentUser',
        'cookies.infoVisible',
        'cookies.cookies',
        'hangar.ships',
        'hangar.detailsVisible',
        'hangar.fleetchartVisible',
        'hangar.fleetchartScale',
        'hangar.publicFleetchartVisible',
        'hangar.publicFleetchartScale',
        'hangar.preview',
        'hangar.money',
        'hangar.starterGuideVisible',
        'models.detailsVisible',
        'models.fleetchartVisible',
        'models.fleetchartScale',
        'models.holoviewerVisible',
        'shop.filterVisible',
        'shops.filterVisible',
        'stations.filterVisible',
        'search.history',
        'fleet.detailsVisible',
        'fleet.fleetchartVisible',
        'fleet.fleetchartScale',
        'fleet.grouped',
        'fleet.money',
        'fleet.preview',
      ],
    }),
  ]
}
