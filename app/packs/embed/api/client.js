import axios from 'axios'
import nprogress from 'nprogress'
import linkHeaderParser from 'parse-link-header'

const client = axios.create({
  baseURL: window.API_ENDPOINT,
  headers: {
    common: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  },
})

const extractMetaInfo = function extractMetaInfo(headers, params) {
  const links = linkHeaderParser(headers.link)
  let meta = null
  if (links) {
    meta = {
      currentPage: parseInt(params.page || 1, 10),
      totalPages: parseInt(
        (links.last && links.last.page) || params.page || 1,
        10,
      ),
    }
  }
  return meta
}

const handleError = async function handleError(error, silent) {
  if (!silent) {
    nprogress.done()
  }

  return {
    data: null,
    meta: null,
    error,
  }
}

const handleResponse = function handleResponse(response, params, silent) {
  if (!silent) {
    nprogress.done()
  }

  const meta = extractMetaInfo(response.headers, params)

  return {
    data: response.data,
    error: null,
    meta,
    params,
  }
}

export async function get(path, params = {}, silent = false) {
  if (!silent) {
    nprogress.start()
  }
  try {
    return handleResponse(
      await client.get(path, {
        params,
      }),
      params,
      silent,
    )
  } catch (error) {
    return handleError(error, silent)
  }
}

const apiClient = {
  get,
  client,
}

export default {
  install(Vue) {
    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$api = apiClient
  },
}
