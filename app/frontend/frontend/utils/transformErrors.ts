import type { FieldError } from "@/services/fyApi";

export const transformErrors = function transformErrors(
  errors: FieldError[],
  fieldMapping?: Record<string, string>,
) {
  if (!errors) {
    return {};
  }

  const errorData: Record<string, string[]> = {};

  errors.forEach((error) => {
    const attribute = fieldMapping?.[error.attribute] ?? error.attribute;

    errorData[attribute] = error.messages.map((message) => message.message);
  });

  return errorData;
};
