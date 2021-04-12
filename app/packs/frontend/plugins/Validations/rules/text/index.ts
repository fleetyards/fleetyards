const regex: RegExp = /^[0-9A-ZÀÂÆÇÉÈÊËÏÎÔŒÙÛÜŸÄÖßÁÍÑÓÚ\-_'"\.,\?!:;\/\s]*$/i

const validate = (value: string): boolean => regex.test(value)

export { validate }

export default {
  validate,
}
