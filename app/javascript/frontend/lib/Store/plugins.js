import createPersistedState from 'vuex-persistedstate'

export default function getStorePlugins() {
  return [createPersistedState({
    key: 'FleetYards',
    paths: [
      'route',
      'lastRoute',
      'backgroundImage',
      'storeVersion',
      'filters',
      'filtersVisible',
      'session.authToken',
      'session.currentUser',
      'session.citizen',
      'session.cookiesAccepted',
      'hangar.ships',
      'hangar.detailsVisible',
      'hangar.filterVisible',
      'hangar.fleetchartVisible',
      'hangar.fleetchartScale',
      'hangar.publicFleetchartVisible',
      'hangar.publicFleetchartScale',
      'models.detailsVisible',
      'models.filterVisible',
      'models.fleetchartVisible',
      'models.fleetchartScale',
      'shop.filterVisible',
      'shops.filterVisible',
      'stations.filterVisible',
      'compare.modelA',
      'compare.modelB',
    ],
  })]
}
