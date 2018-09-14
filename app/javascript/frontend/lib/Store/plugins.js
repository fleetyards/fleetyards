import createPersistedState from 'vuex-persistedstate'

export default function getStorePlugins() {
  return [createPersistedState({
    key: 'FleetYards',
    paths: [
      'appVersion',
      'appCodename',
      'updateAvailable',
      'route',
      'lastRoute',
      'previousRoute',
      'clientKey',
      'authToken',
      'backgroundImage',
      'currentUser',
      'citizen',
      'hangar',
      'storeVersion',
      'compareModelA',
      'compareModelB',
      'tradeHubPrices',
      'tradeHubPricesID',
      'filters',
      'hangarDetailsVisible',
      'hangarFleetchartVisible',
      'hangarFleetchartScale',
      'hangarPublicFleetchartVisible',
      'hangarPublicFleetchartScale',
      'hangarFilterVisible',
      'modelDetailsVisible',
      'modelFilterVisible',
    ],
  })]
}
