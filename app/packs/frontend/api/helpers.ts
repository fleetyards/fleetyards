// eslint-disable-next-line import/prefer-default-export
export const transformErrors = function transformErrors(errors) {
  const errorData = {}

  errors.forEach(error => {
    errorData[error.attribute] = error.messages.map(message => message.message)
  })

  return errorData
}
