import { AxiosError } from 'axios'

export default class BaseCollection {
  primaryKey: string = 'slug'

  currentPage: number | null = 1

  totalPages: number | null = null

  loaded: boolean = false

  setPages(meta: Pagination | null) {
    if (!meta) {
      this.currentPage = 1
      this.totalPages = null
    } else {
      this.currentPage = meta.currentPage
      this.totalPages = meta.totalPages
    }
  }

  extractErrorCode(error: AxiosError | null): string | null {
    return error?.response?.data?.code || null
  }
}
