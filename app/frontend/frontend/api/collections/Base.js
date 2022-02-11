export default class BaseCollection {
  primaryKey = 'slug'

  currentPage = 1

  totalPages = null

  loaded = false

  setPages(meta) {
    if (!meta) {
      this.currentPage = 1
      this.totalPages = null
    } else {
      this.currentPage = meta.currentPage
      this.totalPages = meta.totalPages
    }
  }

  extractErrorCode(error) {
    return error?.response?.data?.code || null
  }
}
