import { isAxiosError } from "axios";
import { ErrorTypesEnum } from "@/shared/components/AsyncData.types";

const statusOf = (error: unknown) =>
  isAxiosError(error) ? error.response?.status : undefined;

// A request that never got an answer: the device is offline, the connection
// dropped, or the host is unreachable. Axios reports all of them without a
// response, which is the only thing that separates them from a server that
// answered with a failure. A cancelled request is not one of them - nothing
// went wrong, the caller walked away.
const unanswered = (error: unknown) =>
  isAxiosError(error) && !error.response && error.code !== "ERR_CANCELED";

/**
 * Which screen a failed request deserves. Shared so every surface answers the
 * same way: a refused request is not a broken server, wherever it surfaces.
 */
export const errorTypeFrom = (error: unknown): ErrorTypesEnum | undefined => {
  const status = statusOf(error);

  if (!status) return unanswered(error) ? ErrorTypesEnum.OFFLINE : undefined;

  if (status === 404) return ErrorTypesEnum.NOT_FOUND;

  if (status === 403) return ErrorTypesEnum.FORBIDDEN;

  return ErrorTypesEnum.ERROR;
};
