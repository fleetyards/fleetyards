import createPersistedState from 'vuex-persistedstate'

export default function getStorePlugins() {
  return [createPersistedState({
    key: 'FleetYards',
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
