import axios from 'axios'
import nprogress from 'nprogress'
import linkHeaderParser from 'parse-link-header'
import axiosDefaults from 'axios/lib/defaults'

const client = axios.create({
  baseURL: window.API_ENDPOINT,
  headers: {
    common: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${window.AUTH_TOKEN}`,
    },
  },
  transformRequest: axiosDefaults.transformRequest.concat(data => {
    nprogress.start()

    return data
  }),
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

const handleError = async function handleError(error) {
  nprogress.done()

  return {
    data: null,
    meta: null,
    error,
  }
}

const handleResponse = function handleResponse(response, params) {
  nprogress.done()

  const meta = extractMetaInfo(response.headers, params)

  return {
    data: response.data,
    error: null,
    meta,
    params,
  }
}

export async function get(path, params = {}) {
  try {
    return handleResponse(
      await client.get(path, {
        params,
        cancelToken: new CancelToken(c => {
          if (cancelations[path]) {
            cancelations[path]('cancel')
          }
          cancelations[path] = c
        }),
      }),
      params,
    )
  } catch (error) {
    return handleError(error)
  }
}

export async function post(path, body = {}) {
  try {
    return handleResponse(await client.post(path, body), body)
  } catch (error) {
    return handleError(error)
  }
}

export async function put(path, body = {}) {
  try {
    return handleResponse(await client.put(path, body), body)
  } catch (error) {
    return handleError(error)
  }
}

export async function destroy(path, data = {}) {
  try {
    return handleResponse(await client.delete(path, { data }))
  } catch (error) {
    return handleError(error)
  }
}

const apiClient = {
  get,
  post,
  put,
  destroy,
  client,
}

export { apiClient }

export default {
  install(Vue) {
    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$api = apiClient
  },
}
