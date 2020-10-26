import axios from 'axios'
import nprogress from 'nprogress'
import Store from 'frontend/lib/Store'
import linkHeaderParser from 'parse-link-header'

const client = axios.create({
  baseURL: window.API_ENDPOINT,
  headers: {
    common: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  },
  withCredentials: true,
})

const { CancelToken } = axios

const cancelations = {}

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

  if (
    error.response &&
    error.response.status === 401 &&
    Store.getters['session/isAuthenticated']
  ) {
    Store.dispatch('session/logout')
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
        cancelToken: new CancelToken(c => {
          const cancelId = [path, params?.cacheId]
            .filter(item => item)
            .join('-')

          if (cancelations[cancelId]) {
            cancelations[cancelId]('cancel')
          }
          cancelations[cancelId] = c
        }),
      }),
      params,
      silent,
    )
  } catch (error) {
    return handleError(error, silent)
  }
}

export async function post(path, body = {}, silent = false) {
  if (!silent) {
    nprogress.start()
  }
  try {
    return handleResponse(await client.post(path, body), body, silent)
  } catch (error) {
    return handleError(error, silent)
  }
}

export async function put(path, body = {}, silent = false) {
  if (!silent) {
    nprogress.start()
  }
  try {
    return handleResponse(await client.put(path, body), body, silent)
  } catch (error) {
    return handleError(error, silent)
  }
}

export async function destroy(path, data = {}, silent = false) {
  if (!silent) {
    nprogress.start()
  }

  try {
    return handleResponse(await client.delete(path, { data }), data, silent)
  } catch (error) {
    return handleError(error, silent)
  }
}

export async function upload(path, body = {}, silent = false) {
  if (!silent) {
    nprogress.start()
  }

  const headers = {
    'Content-Type': 'multipart/form-data',
  }

  try {
    return handleResponse(
      await client.put(path, body, { headers }),
      body,
      silent,
    )
  } catch (error) {
    return handleError(error, silent)
  }
}

export async function download(path, params = {}, silent = false) {
  if (!silent) {
    nprogress.start()
  }
  try {
    return handleResponse(
      await client.get(path, {
        params,
        responseType: 'blob',
      }),
      {},
      silent,
    )
  } catch (error) {
    return handleError(error, silent)
  }
}

const apiClient = {
  get,
  post,
  put,
  destroy,
  download,
  client,
  upload,
}

export default {
  install(Vue) {
    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$api = apiClient
  },
}
