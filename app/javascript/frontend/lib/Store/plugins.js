import createPersistedState from 'vuex-persistedstate'

export default function getStorePlugins() {
  return [createPersistedState({
    key: 'FleetYards',
    paths: [
      'route',
      'backgroundImage',
      'storeVersion',
      'filters',
      'filtersVisible',
      'app.navSlim',
      'session.authToken',
      'session.currentUser',
      'session.cookiesAccepted',
      'hangar.ships',
      'hangar.detailsVisible',
      'hangar.filterVisible',
      'hangar.fleetchartVisible',
      'hangar.fleetchartScale',
      'hangar.publicFleetchartVisible',
      'hangar.publicFleetchartScale',
      'hangar.preview',
      'models.detailsVisible',
      'models.filterVisible',
      'models.fleetchartVisible',
      'models.fleetchartScale',
      'models.holoviewerVisible',
      'shop.filterVisible',
      'shops.filterVisible',
      'stations.filterVisible',
      'compare.modelA',
      'compare.modelB',
      'search.history',
    ],
  })]
}
