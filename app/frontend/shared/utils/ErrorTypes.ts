import { isAxiosError } from "axios";
import { ErrorTypesEnum } from "@/shared/components/AsyncData.types";

const statusOf = (error: unknown) =>
  isAxiosError(error) ? error.response?.status : undefined;

// Both refusals are a 403 and the body is what separates them: a capability
// that is not rolled out answers `forbidden` to everyone, one that is rolled
// out and unbought answers `subscription_required`. Read as a bare status they
// are the same screen, and the second would tell a supporter their clearance
// is wrong when the truth is that nobody has subscribed the fleet yet.
//
// Typed here rather than pulled from the generated client: this file is the
// one place a raw axios error is read, and it should not need regenerating to
// keep compiling.
export const errorCodeFrom = (error: unknown) =>
  isAxiosError(error)
    ? (error.response?.data as { code?: string } | undefined)?.code
    : undefined;

// A request that never got an answer: the device is offline, the connection
// dropped, or the host is unreachable. Axios reports all of them without a
// response, which is the only thing that separates them from a server that
// answered with a failure. A cancelled request is not one of them - nothing
// went wrong, the caller walked away.
function unanswered(error: unknown) {
  return (
    isAxiosError(error) && !error.response && error.code !== "ERR_CANCELED"
  );
}

/**
 * Which screen a failed request deserves. Shared so every surface answers the
 * same way: a refused request is not a broken server, wherever it surfaces.
 */
export const errorTypeFrom = (error: unknown): ErrorTypesEnum | undefined => {
  const status = statusOf(error);

  if (!status) return unanswered(error) ? ErrorTypesEnum.OFFLINE : undefined;

  if (status === 404) return ErrorTypesEnum.NOT_FOUND;

  // Request validation refusing a param - an unknown sort key, a malformed
  // filter. The server is fine; the request is what needs changing.
  if (status === 400) return ErrorTypesEnum.CLIENT_ERROR;

  if (status === 403) {
    return errorCodeFrom(error) === "subscription_required"
      ? ErrorTypesEnum.SUBSCRIPTION_REQUIRED
      : ErrorTypesEnum.FORBIDDEN;
  }

  return ErrorTypesEnum.ERROR;
};
