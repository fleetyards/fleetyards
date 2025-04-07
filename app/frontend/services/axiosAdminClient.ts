import Axios, { type AxiosRequestConfig, type AxiosError } from "axios";
import Qs from "qs";

export const AXIOS_INSTANCE = Axios.create({
  baseURL: `${window.ADMIN_API_ENDPOINT}`,
  withCredentials: true,
  paramsSerializer: (params) =>
    Qs.stringify(params, {
      arrayFormat: "brackets",
      encode: false,
    }),
});

export const axiosClient = <T>(config: AxiosRequestConfig): Promise<T> => {
  const source = Axios.CancelToken.source();

  const headers = {
    ...config.headers,
    Accept: "application/json",
    "Content-Type": "application/json",
  };

  const promise = AXIOS_INSTANCE({
    ...config,
    headers,
    cancelToken: source.token,
  }).then(({ data }) => data);

  // @ts-ignore - cancel is not part of the promise
  promise.cancel = () => {
    source.cancel("Query was cancelled by Vue Query");
  };

  return promise;
};

export default axiosClient;

export type ErrorType<Error> = AxiosError<Error>;
