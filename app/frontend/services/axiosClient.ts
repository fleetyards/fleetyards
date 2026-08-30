import Axios, { type AxiosRequestConfig, type AxiosError } from "axios";
import Qs from "qs";
import { useScDataSourceStore } from "@/shared/stores/scDataSource";

export const AXIOS_INSTANCE = Axios.create({
  baseURL: `${window.API_ENDPOINT}`,
  withCredentials: true,
  paramsSerializer: (params) =>
    Qs.stringify(params, {
      arrayFormat: "brackets",
      encode: false,
    }),
});

export const axiosClient = <T>(config: AxiosRequestConfig): Promise<T> => {
  const source = Axios.CancelToken.source();

  // One choke point for which build of the game data a request reads, mirroring
  // `ScData::Source` on the other side. Nothing is sent for the default, so a
  // reader who has never touched the switch sends what it always sent.
  const scDataSource = useScDataSourceStore().requestParam;

  const headers = {
    ...config.headers,
    Accept: "application/json",
    "Content-Type": "application/json",
  };

  const promise = AXIOS_INSTANCE({
    ...config,
    headers,
    params: scDataSource
      ? { ...(config.params as object), source: scDataSource }
      : config.params,
    cancelToken: source.token,
  }).then(({ data }) => data);

  // @ts-ignore - cancel is not part of the promise
  promise.cancel = () => {
    source.cancel("Query was cancelled by Vue Query");
  };

  return promise;
};

export type ErrorType<Error> = AxiosError<Error>;
