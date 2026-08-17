import { isAxiosError } from "axios";
import { ErrorTypesEnum } from "@/shared/components/AsyncData.types";

const statusOf = (error: unknown) =>
  isAxiosError(error) ? error.response?.status : undefined;

/**
 * Which screen a failed request deserves. Shared so every surface answers the
 * same way: a refused request is not a broken server, wherever it surfaces.
 */
export const errorTypeFrom = (error: unknown): ErrorTypesEnum | undefined => {
  const status = statusOf(error);

  if (!status) return undefined;

  if (status === 404) return ErrorTypesEnum.NOT_FOUND;

  if (status === 403) return ErrorTypesEnum.FORBIDDEN;

  return ErrorTypesEnum.ERROR;
};
