import Vue from 'vue'
import Vuex from 'vuex'
import { apiClient } from 'frontend/lib/ApiClient'
import {
  format, parse, differenceInMinutes, isBefore, subMinutes,
} from 'date-fns'
import getStorePlugins from './plugins'

Vue.use(Vuex)

const getLeeway = (expiresAt) => {
  const leewayAmount = differenceInMinutes(expiresAt, new Date()) / 3
  return subMinutes(expiresAt, Math.max(leewayAmount, 10))
}

const initialState = {
  locale: 'en-US',
  mobile: false,
  appVersion: window.APP_VERSION,
  appCodename: window.APP_CODENAME,
  storeVersion: null,
  authToken: null,
  authTokenRenewAt: null,
  backgroundImage: null,
  hangar: [],
  currentUser: null,
  citizen: null,
  lastRoute: null,
  previousRoute: null,
  online: true,
  tradeHubPrices: {},
  tradeHubPricesID: null,
  filters: {},
  hangarDetailsVisible: false,
  hangarFleetchartVisible: false,
  hangarFleetchartScale: 100,
  hangarPublicFleetchartVisible: false,
  hangarPublicFleetchartScale: 100,
  hangarFilterVisible: true,
  shopFilterVisible: false,
  stationFilterVisible: true,
  shopsFilterVisible: true,
  navCollapsed: true,
  overlayVisible: false,
  modelDetailsVisible: false,
  modelFilterVisible: true,
  modelFleetchartVisible: false,
  modelFleetchartScale: 100,
  modelBackRoute: null,
  shopBackRoute: null,
  stationBackRoute: null,
}

const store = new Vuex.Store({
  state: initialState,
  getters: {
    appVersion(state) {
      return state.appVersion
    },
    appCodename(state) {
      return state.appCodename
    },
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
    HangarFleetchartScale(state) {
      return state.hangarFleetchartScale
    },
    hangarPublicFleetchartVisible(state) {
      return state.hangarPublicFleetchartVisible
    },
    HangarPublicFleetchartScale(state) {
      return state.hangarPublicFleetchartScale
    },
    hangarFilterVisible(state) {
      return state.hangarFilterVisible
    },
    shopFilterVisible(state) {
      return state.shopFilterVisible
    },
    stationFilterVisible(state) {
      return state.stationFilterVisible
    },
    shopsFilterVisible(state) {
      return state.shopsFilterVisible
    },
    navCollapsed(state) {
      return state.navCollapsed
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
    modelFleetchartVisible(state) {
      return state.modelFleetchartVisible
    },
    ModelFleetchartScale(state) {
      return state.modelFleetchartScale
    },
    modelBackRoute(state) {
      return state.modelBackRoute
    },
    shopBackRoute(state) {
      return state.shopBackRoute
    },
    stationBackRoute(state) {
      return state.stationBackRoute
    },
    isUpdateAvailable(state) {
      return state.appVersion !== window.APP_VERSION
    },
  },
  actions: {
    updateAppVersion({ state, commit }, payload = {}) {
      if (payload.version && state.appVersion !== payload.version) {
        commit('setAppVersion', payload.version)
        commit('setAppCodename', payload.codename)
      }
    },
    async logout({ commit }, fromError = false) {
      if (!fromError) {
        try {
          await apiClient.destroy('sessions')
        } catch (error) {
        // console.error(error)
        }
      }
      commit('setAuthTokenRenewAt', null)
      commit('setAuthToken', null)
      commit('setHangar', [])
      commit('setCurrentUser', null)
      commit('setCitizen', null)
    },
    async renewSession({ dispatch, state }) {
      if (state.authTokenRenewAt && isBefore(new Date(), parse(state.authTokenRenewAt))) {
        return
      }

      try {
        const response = await apiClient.put('sessions/renew')
        if (!response.error) {
          dispatch('login', response.data)
        }
      } catch (error) {
        // console.error(error)
      }
    },
    login({ commit }, payload) {
      commit('setAuthToken', payload.token)
      const renewAt = getLeeway(parse(payload.expires))
      commit('setAuthTokenRenewAt', format(renewAt))
    },
    toggleModelFilter({ commit, state }) {
      commit('setModelFilterVisible', !state.modelFilterVisible)
    },
    toggleModelDetails({ commit, state }) {
      commit('setModelDetailsVisible', !state.modelDetailsVisible)
    },
    toggleModelFleetchart({ commit, state }) {
      commit('setModelFleetchartVisible', !state.modelFleetchartVisible)
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
    toggleShopFilter({ commit, state }) {
      commit('setShopFilterVisible', !state.shopFilterVisible)
    },
    toggleStationFilter({ commit, state }) {
      commit('setStationFilterVisible', !state.stationFilterVisible)
    },
    toggleShopsFilter({ commit, state }) {
      commit('setShopsFilterVisible', !state.shopsFilterVisible)
    },
  },
  /* eslint-disable no-param-reassign */
  mutations: {
    setAppVersion(state, payload) {
      state.appVersion = payload
    },
    setAppCodename(state, payload) {
      state.appCodename = payload
    },
    reset(state) {
      Object.assign(state, initialState)
    },
    resetTradeHubPrices(state) {
      state.tradeHubPrices = initialState.tradeHubPrices
      state.tradeHubPricesID = initialState.tradeHubPricesID
    },
    setStoreVersion(state, payload) {
      state.storeVersion = payload
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
    setAuthTokenRenewAt(state, payload) {
      state.authTokenRenewAt = payload
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
    toggleNav(state) {
      state.navCollapsed = !state.navCollapsed
    },
    showOverlay(state) {
      state.overlayVisible = true
    },
    hideOverlay(state) {
      state.overlayVisible = false
    },
    openNav(state) {
      state.navCollapsed = false
    },
    closeNav(state) {
      state.navCollapsed = true
    },
    setModelFilterVisible(state, payload) {
      state.modelFilterVisible = payload
    },
    setModelDetailsVisible(state, payload) {
      state.modelDetailsVisible = payload
    },
    setModelFleetchartVisible(state, payload) {
      state.modelFleetchartVisible = payload
    },
    setModelFleetchartScale(state, payload) {
      state.modelFleetchartScale = payload
    },
    setModelBackRoute(state, payload) {
      state.modelBackRoute = payload
    },
    setShopBackRoute(state, payload) {
      state.shopBackRoute = payload
    },
    setStationBackRoute(state, payload) {
      state.stationBackRoute = payload
    },
    setShopFilterVisible(state, payload) {
      state.shopFilterVisible = payload
    },
    setStationFilterVisible(state, payload) {
      state.stationFilterVisible = payload
    },
    setShopsFilterVisible(state, payload) {
      state.shopsFilterVisible = payload
    },
  },
  /* eslint-enable no-param-reassign */
  plugins: getStorePlugins(),
})

export default store
