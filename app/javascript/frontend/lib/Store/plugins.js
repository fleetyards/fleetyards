import createPersistedState from 'vuex-persistedstate'

export default function getStorePlugins() {
  return [
    createPersistedState({
      key: 'FleetYards',
      paths: [
        'storeVersion',
        'app.navSlim',
        'session.authenticated',
        'cookies.infoVisible',
        'cookies.cookies',
        'hangar.ships',
        'hangar.detailsVisible',
        'hangar.fleetchartScale',
        'hangar.publicFleetchartScale',
        'hangar.preview',
        'hangar.money',
        'hangar.starterGuideVisible',
        'hangar.perPage',
        'hangar.gridView',
        'models.detailsVisible',
        'models.fleetchartScale',
        'models.holoviewerVisible',
        'search.history',
        'fleet.detailsVisible',
        'fleet.fleetchartScale',
        'fleet.grouped',
        'fleet.money',
        'fleet.preview',
        'shoppingCart.items',
      ],
    }),
  ]
}
