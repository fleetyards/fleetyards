import { transformErrors } from "@/frontend/api/helpers";
import type { AxiosError } from "axios";

export default class BaseCollection<T, P> {
  primaryKey = "slug";

  records: T[] = [];

  record: T | undefined = undefined;

  params: P | undefined = undefined;

  currentPage: number | null = 1;

  totalPages: number | null = null;

  async findAll(_params: P): Promise<TCollectionResponse<T>> {
    throw new Error("Not implemented");
  }

  resetRecords() {
    this.records = [];
  }

  setPages(meta?: TPagination) {
    if (!meta) {
      this.currentPage = 1;
      this.totalPages = null;
    } else {
      this.currentPage = meta.currentPage;
      this.totalPages = meta.totalPages;
    }
  }

  extractErrorCode(error?: AxiosError): string {
    return error?.response?.data?.code as string;
  }

  extractErrors(error?: AxiosError): TErrorMessages | undefined {
    if (!error?.response || !error?.response.data) {
      return undefined;
    }

    const { data } = error.response;

    return transformErrors(data.errors);
  }

  collectionResponse(error?: AxiosError): TCollectionResponse<T> {
    if (error) {
      return {
        error: this.extractErrorCode(error),
      };
    }

    return {
      data: this.records,
    };
  }

  recordResponse(
    data?: T,
    error?: AxiosError,
    persist = false
  ): TRecordResponse<T> {
    if (!error && data) {
      if (persist) {
        this.record = data;
      }

      return {
        data,
      };
    }

    return {
      error: this.extractErrorCode(error),
      errors: this.extractErrors(error),
      message: error?.response?.data?.message,
    };
  }

  isErrorResponse(
    response: TRecordResponse<T>
  ): response is TRecordErrorResponse {
    return "error" in response;
  }
}
