import axios, { AxiosResponse } from "axios";
import nprogress from "nprogress";
import Store from "@/frontend/lib/Store";
import Qs from "qs";
import { useI18n } from "@/frontend/composables/useI18n";
import linkHeaderParser from "./linkHeaderParser";

type ApiResponseMeta = {
  currentPage: number;
  totalPages: number;
};

export type ApiResponse = {
  data: any;
  params: any;
  meta: ApiResponseMeta | null;
  error: null;
};

export type ApiErrorResponse = {
  data: null;
  params: any;
  meta: null;
  error: any;
};

const client = axios.create({
  baseURL: window.ADMIN_API_ENDPOINT,
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

const extractMetaInfo = function extractMetaInfo(
  headers: any,
  params: any,
): ApiResponseMeta | null {
  const links = linkHeaderParser(headers.link);

  let meta: ApiResponseMeta | null = null;

  if (links) {
    meta = {
      currentPage: parseInt(params.page || 1, 10),
      totalPages: parseInt(
        (links.last && links.last.page) || params.page || 1,
        10,
      ),
    };
  }

  return meta;
};

const handleError = async function handleError(
  error: any,
  params: any,
  silent: boolean,
): Promise<ApiErrorResponse> {
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
    data: null,
    params,
    meta: null,
    error,
  };
};

const handleResponse = function handleResponse(
  response: AxiosResponse,
  params: any,
  silent: boolean,
): ApiResponse {
  if (!silent) {
    nprogress.done();
  }

  const meta = extractMetaInfo(response.headers, params);

  return {
    data: response.data,
    params,
    meta,
    error: null,
  };
};

export async function get(path: string, params: any = {}, silent = false) {
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
    return handleResponse(response, params, silent);
  } catch (error) {
    return handleError(error, params, silent);
  }
}

export async function post(path: string, body = {}, silent = false) {
  if (!silent) {
    nprogress.start();
  }

  try {
    return handleResponse(
      await client.post(path, body, {
        headers: {
          ...languageHeader(),
        },
      }),
      body,
      silent,
    );
  } catch (error) {
    return handleError(error, body, silent);
  }
}

export async function put(path: string, body = {}, silent = false) {
  if (!silent) {
    nprogress.start();
  }

  try {
    return handleResponse(
      await client.put(path, body, {
        headers: {
          ...languageHeader(),
        },
      }),
      body,
      silent,
    );
  } catch (error) {
    return handleError(error, body, silent);
  }
}

export async function destroy(path: string, data = {}, silent = false) {
  if (!silent) {
    nprogress.start();
  }

  try {
    return handleResponse(
      await client.delete(path, {
        data,

        headers: {
          ...languageHeader(),
        },
      }),
      data,
      silent,
    );
  } catch (error) {
    return handleError(error, data, silent);
  }
}

export async function upload(path: string, body = {}, silent = false) {
  if (!silent) {
    nprogress.start();
  }

  const headers = {
    "Content-Type": "multipart/form-data",
    ...languageHeader(),
  };

  try {
    return handleResponse(
      await client.put(path, body, { headers }),
      body,
      silent,
    );
  } catch (error) {
    return handleError(error, body, silent);
  }
}

export async function download(path: string, params = {}, silent = false) {
  if (!silent) {
    nprogress.start();
  }

  try {
    return handleResponse(
      await client.get(path, {
        params,
        responseType: "blob",
        headers: {
          ...languageHeader(),
        },
      }),
      {},
      silent,
    );
  } catch (error) {
    return handleError(error, params, silent);
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
