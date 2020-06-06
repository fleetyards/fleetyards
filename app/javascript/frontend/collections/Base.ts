export default class BaseCollection {
  currentPage: number | null = null

  totalPages: number | null = null

  setPages(meta: Pagination | null) {
    if (!meta) {
      this.currentPage = null
      this.totalPages = null
    } else {
      this.currentPage = meta.currentPage
      this.totalPages = meta.totalPages
    }
  }
}
