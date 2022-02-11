export const transformErrors = function transformErrors(errors) {
  if (!errors) {
    return null
  }

  const errorData = {}

  errors.forEach((error) => {
    errorData[error.attribute] = error.messages.map(
      (message) => message.message
    )
  })

  return errorData
}
