import { useI18n } from "@/frontend/composables/useI18n";
import Store from "@/frontend/lib/Store";
import axios from "axios";
import type { AxiosResponse, AxiosError, AxiosResponseHeaders } from "axios";
import nprogress from "nprogress";
import Qs from "qs";

import linkHeaderParser from "./linkHeaderParser";

type TApiResponseMeta = {
  currentPage: number;
  totalPages: number;
};

type TApiParams = {
  [key: string]:
    | string
    | string[]
    | number
    | number[]
    | boolean
    | null
    | undefined
    | TApiParams;
};

export type TApiResponse<T> = {
  data: T;
  params: TApiParams;
  meta?: TApiResponseMeta;
  error?: undefined;
};

export type TApiErrorResponse = {
  data?: undefined;
  params: TApiParams;
  meta?: undefined;
  error: AxiosError;
};

const client = axios.create({
  baseURL: window.API_ENDPOINT,
  headers: {
    Accept: "application/json",
    "Content-Type": "application/json",
  },
  paramsSerializer: (params) =>
    Qs.stringify(params, {
      arrayFormat: "brackets",
      encode: false,
    }),
  withCredentials: true,
});

const extractMetaInfo = (
  headers: AxiosResponseHeaders,
  params: TApiParams
): TApiResponseMeta | undefined => {
  const links = linkHeaderParser(headers.link);

  if (links) {
    const lastPage =
      links.last && links.last.page ? parseInt(links.last.page, 10) : null;
    const page = params.page ? parseInt(params.page as string, 10) : 1;

    return {
      currentPage: page,
      totalPages: lastPage || page,
    };
  }

  return undefined;
};

const handleError = async function handleError(
  error: AxiosError,
  params: TApiParams,
  silent: boolean
): Promise<TApiErrorResponse> {
  if (!silent) {
    nprogress.done();
  }

  if (
    error.response &&
    error.response.status === 401 &&
    Store.getters["session/isAuthenticated"]
  ) {
    Store.dispatch("session/logout");
  }

  return {
    data: undefined,
    params,
    meta: undefined,
    error,
  };
};

const handleResponse = function handleResponse<T>(
  response: AxiosResponse<T>,
  params: TApiParams,
  silent: boolean
): TApiResponse<T> {
  if (!silent) {
    nprogress.done();
  }

  const meta = extractMetaInfo(response.headers, params);

  return {
    data: response.data,
    params,
    meta,
    error: undefined,
  };
};

export async function get<T>(
  path: string,
  params: TApiParams = {},
  silent = false
) {
  if (!silent) {
    nprogress.start();
  }
  try {
    const response = await client.get(path, {
      params,

      headers: {
        ...languageHeader(),
      },
    });
    return handleResponse<T>(response, params, silent);
  } catch (error) {
    return handleError(error as AxiosError, params, silent);
  }
}

export async function post<T>(path: string, body = {}, silent = false) {
  if (!silent) {
    nprogress.start();
  }

  try {
    return handleResponse<T>(
      await client.post(path, body, {
        headers: {
          ...languageHeader(),
        },
      }),
      body,
      silent
    );
  } catch (error) {
    return handleError(error as AxiosError, body, silent);
  }
}

export async function put<T>(path: string, body = {}, silent = false) {
  if (!silent) {
    nprogress.start();
  }

  try {
    return handleResponse<T>(
      await client.put(path, body, {
        headers: {
          ...languageHeader(),
        },
      }),
      body,
      silent
    );
  } catch (error) {
    return handleError(error as AxiosError, body, silent);
  }
}

export async function destroy<T>(path: string, data = {}, silent = false) {
  if (!silent) {
    nprogress.start();
  }

  try {
    return handleResponse<T>(
      await client.delete(path, {
        data,

        headers: {
          ...languageHeader(),
        },
      }),
      data,
      silent
    );
  } catch (error) {
    return handleError(error as AxiosError, data, silent);
  }
}

export async function upload<T>(path: string, body = {}, silent = false) {
  if (!silent) {
    nprogress.start();
  }

  const headers = {
    "Content-Type": "multipart/form-data",
    ...languageHeader(),
  };

  try {
    return handleResponse<T>(
      await client.put(path, body, { headers }),
      body,
      silent
    );
  } catch (error) {
    return handleError(error as AxiosError, body, silent);
  }
}

export async function download<T>(
  path: string,
  params: TApiParams = {},
  silent = false
) {
  if (!silent) {
    nprogress.start();
  }

  try {
    return handleResponse<T>(
      await client.get(path, {
        params,
        responseType: "blob",
        headers: {
          ...languageHeader(),
        },
      }),
      {},
      silent
    );
  } catch (error) {
    return handleError(error as AxiosError, params, silent);
  }
}

const languageHeader = () => {
  const { I18n } = useI18n();

  return {
    "Accept-Language": `${I18n.currentLocale()},en;q=0.8`,
  };
};

export const apiClient = {
  get,
  post,
  put,
  destroy,
  download,
  client,
  upload,
};

export default {
  // tslint:disable-next-line
  install(Vue: any) {
    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$api = apiClient;
  },
};
