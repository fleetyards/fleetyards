import createPersistedState from 'vuex-persistedstate'

export default function getStorePlugins() {
  return [createPersistedState({
    paths: [
      'route',
      'lastRoute',
      'previousRoute',
      'authToken',
      'backgroundImage',
      'currentUser',
      'citizen',
      'hangar',
      'version',
      'compareModelA',
      'compareModelB',
      'tradeHubPrices',
      'tradeHubPricesID',
      'filters',
      'hangarDetails',
      'hangarFleetchart',
      'hangarFleetchartScale',
      'hangarPublicFleetchart',
      'hangarPublicFleetchartScale',
      'hangarFilterVisible',
    ],
  })]
}
