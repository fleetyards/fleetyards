import { type ApiError } from "@/services/fyApi";
import { type AxiosError } from "axios";

export type AsyncStatus = {
  fetchStatus: Ref<string>;
  isError: Ref<boolean>;
  isLoading: Ref<boolean>;
  isFetching: Ref<boolean>;
  isRefetching: Ref<boolean>;
  refetch?: () => void;
  error: Ref<AxiosError | ApiError | Error | null>;
};

export enum ErrorTypesEnum {
  NOT_FOUND = "NOT_FOUND",
  ERROR = "ERROR",
  UNDEFINED = "UNDEFINED",
}
