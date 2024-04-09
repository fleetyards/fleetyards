import { type ApiError } from "@/services/fyApi";
import { type AxiosError } from "axios";

export type AsyncStatus = {
  fetchStatus: Ref<string>;
  isError: Ref<boolean>;
  error?: Ref<ApiError | AxiosError>;
  isLoading: Ref<boolean>;
  isFetching: Ref<boolean>;
  isRefetching: Ref<boolean>;
  refetch?: () => void;
};

export enum ErrorTypesEnum {
  NOT_FOUND = "NOT_FOUND",
  ERROR = "ERROR",
  UNDEFINED = "UNDEFINED",
}
