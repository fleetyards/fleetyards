import Vue from 'vue'
import Vuex from 'vuex'
import { apiClient } from 'frontend/lib/ApiClient'
import getStorePlugins from './plugins'

Vue.use(Vuex)

const initialState = {
  locale: 'en-US',
  mobile: false,
  authToken: null,
  backgroundImage: null,
  hangar: [],
  currentUser: null,
  citizen: null,
  lastRoute: null,
  previousRoute: null,
  version: null,
  online: true,
  tradeHubPrices: {},
  tradeHubPricesID: null,
  filters: {},
  hangarDetailsVisible: false,
  hangarFleetchartVisible: false,
  hangarFleetchartScale: 1,
  hangarPublicFleetchartVisible: false,
  hangarPublicFleetchartScale: 1,
  hangarFilterVisible: true,
  navbarCollapsed: true,
  overlayVisible: false,
  modelDetailsVisible: false,
  modelFilterVisible: true,
}

const store = new Vuex.Store({
  state: initialState,
  getters: {
    isAuthenticated(state) {
      return state.authToken !== null
    },
    mobile(state) {
      return state.mobile
    },
    hangar(state) {
      return state.hangar
    },
    currentUser(state) {
      return state.currentUser
    },
    citizen(state) {
      return state.citizen
    },
    previousRoute(state) {
      return state.previousRoute
    },
    tradeHubPrices(state) {
      return state.tradeHubPrices
    },
    tradeHubPricesID(state) {
      return state.tradeHubPricesID
    },
    hangarDetailsVisible(state) {
      return state.hangarDetailsVisible
    },
    hangarFleetchartVisible(state) {
      return state.hangarFleetchartVisible
    },
    hangarPublicFleetchartVisible(state) {
      return state.hangarPublicFleetchartVisible
    },
    hangarFilterVisible(state) {
      return state.hangarFilterVisible
    },
    navbarCollapsed(state) {
      return state.navbarCollapsed
    },
    overlayVisible(state) {
      return state.overlayVisible
    },
    modelDetailsVisible(state) {
      return state.modelDetailsVisible
    },
    modelFilterVisible(state) {
      return state.modelFilterVisible
    },
  },
  actions: {
    async logout({ commit }) {
      commit('setAuthToken', null)
      commit('setHangar', [])
      commit('setCurrentUser', null)
      commit('setCitizen', null)

      try {
        await apiClient.destroy('sessions')
      } catch (_error) {
        // ignoring logout error
      }
    },
    login({ commit }, authToken) {
      commit('setAuthToken', authToken)
    },
    renewToken({ commit }, token) {
      commit('setAuthToken', token)
    },
    toggleModelFilter({ commit, state }) {
      commit('setModelFilterVisible', !state.modelFilterVisible)
    },
    toggleModelDetails({ commit, state }) {
      commit('setModelDetailsVisible', !state.modelDetailsVisible)
    },
    toggleHangarDetails({ commit, state }) {
      commit('setHangarDetailsVisible', !state.hangarDetailsVisible)
    },
    toggleHangarFleetchart({ commit, state }) {
      commit('setHangarFleetchartVisible', !state.hangarFleetchartVisible)
    },
    toggleHangarPublicFleetchart({ commit, state }) {
      commit('setHangarPublicFleetchartVisible', !state.hangarPublicFleetchartVisible)
    },
    toggleHangarFilter({ commit, state }) {
      commit('setHangarFilterVisible', !state.hangarFilterVisible)
    },
  },
  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, initialState)
    },
    resetTradeHubPrices(state) {
      state.tradeHubPrices = initialState.tradeHubPrices
      state.tradeHubPricesID = initialState.tradeHubPricesID
    },
    setStoreVersion(state, payload) {
      state.version = payload
    },
    setLocale(state, locale) {
      state.locale = locale
    },
    setMobile(state, payload) {
      state.mobile = payload
    },
    setOnlineStatus(state, payload) {
      state.online = payload
    },
    setAuthToken(state, payload) {
      state.authToken = payload
    },
    logout(state) {
      state.authToken = null
      state.hangar = []
      state.currentUser = null
      state.citizen = null
    },
    setCurrentUser(state, payload) {
      state.currentUser = Object.assign({}, state.currentUser, payload)
    },
    resetCitizen(state) {
      state.citizen = null
    },
    setCitizen(state, payload) {
      state.citizen = Object.assign({}, state.citizen, payload)
    },
    setBackgroundImage(state, payload) {
      state.backgroundImage = payload
    },
    setHangar(state, payload) {
      state.hangar = payload
    },
    addToHangar(state, payload) {
      state.hangar.push(payload)
    },
    removeFromHangar(state, payload) {
      state.hangar.splice(state.hangar.indexOf(payload), 1)
    },
    setLastRoute(state, payload) {
      state.lastRoute = Object.assign({}, state.lastRoute, payload)
    },
    setPreviousRoute(state, payload) {
      state.previousRoute = Object.assign({}, state.previousRoute, payload)
    },
    setTradeHubPrices(state, payload) {
      state.tradeHubPrices = payload
    },
    setTradeHubPricesID(state, payload) {
      state.tradeHubPricesID = payload
    },
    setFilters(state, payload) {
      state.filters = Object.assign({}, state.filters, payload)
    },
    setHangarDetailsVisible(state, payload) {
      state.hangarDetailsVisible = payload
    },
    setHangarFleetchartVisible(state, payload) {
      state.hangarFleetchartVisible = payload
    },
    setHangarPublicFleetchartVisible(state, payload) {
      state.hangarPublicFleetchartVisible = payload
    },
    setHangarFilterVisible(state, payload) {
      state.hangarFilterVisible = payload
    },
    setHangarFleetchartScale(state, payload) {
      state.hangarFleetchartScale = payload
    },
    setHangarPublicFleetchartScale(state, payload) {
      state.hangarPublicFleetchartScale = payload
    },
    toggleNavbar(state) {
      state.navbarCollapsed = !state.navbarCollapsed
    },
    showOverlay(state) {
      state.overlayVisible = true
    },
    hideOverlay(state) {
      state.overlayVisible = false
    },
    closeNavbar(state) {
      state.navbarCollapsed = true
    },
    setModelFilterVisible(state, payload) {
      state.modelFilterVisible = payload
    },
    setModelDetailsVisible(state, payload) {
      state.modelDetailsVisible = payload
    },
  },
  /* eslint-enable no-param-reassign */
  plugins: getStorePlugins(),
})

export default store
