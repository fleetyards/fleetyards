export default class BaseCollection {
  primaryKey: string = 'slug'

  currentPage: number | null = null

  totalPages: number | null = null

  loaded: boolean = false

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
