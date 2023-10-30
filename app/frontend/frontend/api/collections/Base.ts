export default class BaseCollection {
  primaryKey = "slug";

  currentPage: number | null = 1;

  totalPages: number | null = null;

  loaded = false;

  setPages(meta?: Pagination) {
    if (!meta) {
      this.currentPage = 1;
      this.totalPages = null;
    } else {
      this.currentPage = meta.currentPage;
      this.totalPages = meta.totalPages;
    }
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  extractErrorCode(error: any): string | null {
    return error?.response?.data?.code || null;
  }
}
