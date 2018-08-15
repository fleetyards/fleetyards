import Vue from 'vue'
import axios from 'axios'
import nprogress from 'nprogress'
import Store from 'frontend/lib/Store'
import { alert } from 'frontend/lib/Noty'
import I18n from 'frontend/lib/I18n'
import linkHeaderParser from 'parse-link-header'

const client = axios.create({
  baseURL: process.env.API_URL,
})

client.interceptors.request.use((config) => {
  const clientConfig = config
  clientConfig.headers.common.Accept = 'application/json'
  clientConfig.headers.common['Content-Type'] = 'application/json'

  if (Store.getters.isAuthenticated) {
    clientConfig.headers.common.Authorization = `Bearer ${Store.state.authToken}`
  }
  return clientConfig
}, error => Promise.reject(error))

const extractMetaInfo = function extractMetaInfo(headers, params) {
  const links = linkHeaderParser(headers.link)
  let meta = null
  if (links) {
    meta = {
      currentPage: parseInt(params.page || 1, 10),
      totalPages: parseInt((links.last && links.last.page) || params.page || 1, 10),
    }
  }
  return meta
}

const handleResponse = function handleResponse(response, callback, params) {
  const meta = extractMetaInfo(response.headers, params)
  nprogress.done()

  if (callback) {
    callback({
      data: response.data, error: null, meta, params,
    })
  }

  return {
    data: response.data, error: null, meta, params,
  }
}

const handleError = function handleError(error, callback) {
  nprogress.done()

  if (!error.response || !error.response.data || !error.response.data.message) {
    alert(I18n.t('messages.error.default'))
  }

  if (error.response && error.response.status === 401 && Store.getters.isAuthenticated) {
    Store.commit('logout')
  }

  if (callback) {
    callback({ data: null, meta: null, error })
  }

  return { data: null, meta: null, error }
}

export function get(path, params = {}, callback) {
  nprogress.start()
  return client.get(path, { params })
    .then(response => handleResponse(response, callback, params))
    .catch(error => handleError(error, callback))
}

export function post(path, body = {}, callback) {
  nprogress.start()
  return client.post(path, body)
    .then(response => handleResponse(response, callback, body))
    .catch(error => handleError(error, callback))
}

export function put(path, body = {}, callback) {
  nprogress.start()
  return client.put(path, body)
    .then(response => handleResponse(response, callback, body))
    .catch(error => handleError(error, callback))
}

export function destroy(path, callback) {
  nprogress.start()
  return client.delete(path)
    .then(response => handleResponse(response, callback))
    .catch(error => handleError(error, callback))
}

Vue.prototype.$api = {
  get, post, put, destroy, client,
}
