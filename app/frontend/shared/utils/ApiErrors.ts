import { isAxiosError } from "axios";
import type {
  FieldError,
  StandardError,
  ValidationError,
} from "@/services/fyApi";

const payloadFrom = <T>(error: unknown): T | undefined =>
  isAxiosError<T>(error) ? error.response?.data : undefined;

const toFormErrors = (
  errors: FieldError[] | undefined,
  fieldMapping?: Record<string, string>,
) => {
  const formErrors: Record<string, string[]> = {};

  errors?.forEach((error) => {
    const field = fieldMapping?.[error.attribute] ?? error.attribute;

    formErrors[field] = error.messages.map((message) => message.message);
  });

  return formErrors;
};

export const validationErrorFrom = (
  error: unknown,
  fieldMapping?: Record<string, string>,
) => {
  const payload = payloadFrom<ValidationError>(error);

  return {
    code: payload?.code,
    message: payload?.message,
    errors: payload?.errors ?? [],
    formErrors: toFormErrors(payload?.errors, fieldMapping),
  };
};

export const standardErrorFrom = (error: unknown) => {
  const payload = payloadFrom<StandardError>(error);

  return {
    code: payload?.code,
    message: payload?.message,
  };
};

/*
 * The first reason a record was refused, as a sentence. An action with no form
 * to mark up has nowhere to put field errors, and the envelope's own message
 * only says that it failed -- not that the member is already in another
 * squadron.
 */
export const firstErrorMessageFrom = (error: unknown) =>
  validationErrorFrom(error).errors.flatMap((fieldError) =>
    fieldError.messages.map((message) => message.message),
  )[0];
