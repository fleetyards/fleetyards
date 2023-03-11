export const transformErrors = (
  errors?: TApiError[]
): TErrorMessages | undefined => {
  if (!errors) {
    return undefined;
  }

  const errorData: TErrorMessages = {};

  errors.forEach((error) => {
    errorData[error.attribute] = error.messages.map(
      (message) => message.message
    );
  });

  return errorData;
};
