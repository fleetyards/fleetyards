import axios, { AxiosResponse } from 'axios'
import nprogress from 'nprogress'
import Store from 'frontend/lib/Store'
import linkHeaderParser from 'parse-link-header'
import Qs from 'qs'

type ApiResponseMeta = {
  currentPage: number
  totalPages: number
}

export type ApiResponse = {
  data: any
  params: any
  meta: ApiResponseMeta | null
  error: null
}

export type ApiErrorResponse = {
  data: null
  params: any
  meta: null
  error: any
}

const client = axios.create({
  baseURL: window.API_ENDPOINT,
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  },
  paramsSerializer: params =>
    Qs.stringify(params, {
      arrayFormat: 'brackets',
      encode: false,
    }),
  withCredentials: true,
})

const extractMetaInfo = function extractMetaInfo(
  headers: any,
  params: any,
): ApiResponseMeta | null {
  const links = linkHeaderParser(headers.link)

  let meta: ApiResponseMeta | null = null

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

const handleError = async function handleError(
  error: any,
  params: any,
  silent: boolean,
): Promise<ApiErrorResponse> {
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
    params,
    meta: null,
    error,
  }
}

const handleResponse = function handleResponse(
  response: AxiosResponse,
  params: any,
  silent: boolean,
): ApiResponse {
  if (!silent) {
    nprogress.done()
  }

  const meta = extractMetaInfo(response.headers, params)

  return {
    data: response.data,
    params,
    meta,
    error: null,
  }
}

export async function get(
  path: string,
  params: any = {},
  silent: boolean = false,
) {
  if (!silent) {
    nprogress.start()
  }
  try {
    const response = await client.get(path, {
      params,
    })
    return handleResponse(response, params, silent)
  } catch (error) {
    return handleError(error, params, silent)
  }
}

export async function post(path: string, body = {}, silent: boolean = false) {
  if (!silent) {
    nprogress.start()
  }
  try {
    return handleResponse(await client.post(path, body), body, silent)
  } catch (error) {
    return handleError(error, body, silent)
  }
}

export async function put(path: string, body = {}, silent: boolean = false) {
  if (!silent) {
    nprogress.start()
  }
  try {
    return handleResponse(await client.put(path, body), body, silent)
  } catch (error) {
    return handleError(error, body, silent)
  }
}

export async function destroy(
  path: string,
  data = {},
  silent: boolean = false,
) {
  if (!silent) {
    nprogress.start()
  }

  try {
    return handleResponse(await client.delete(path, { data }), data, silent)
  } catch (error) {
    return handleError(error, data, silent)
  }
}

export async function upload(path: string, body = {}, silent: boolean = false) {
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
    return handleError(error, body, silent)
  }
}

export async function download(
  path: string,
  params = {},
  silent: boolean = false,
) {
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
    return handleError(error, params, silent)
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
  // tslint:disable-next-line
  install(Vue: any) {
    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$api = apiClient
  },
}
