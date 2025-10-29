import type { FieldError } from "@/services/fyApi";

export const transformErrors = function transformErrors(errors: FieldError[]) {
  if (!errors) {
    return {};
  }

  const errorData: Record<string, string[]> = {};

  errors.forEach((error) => {
    errorData[error.attribute] = error.messages.map(
      (message) => message.message,
    );
  });

  return errorData;
};
