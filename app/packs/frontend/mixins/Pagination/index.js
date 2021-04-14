import Paginator from 'frontend/core/components/Paginator'

export default {
  components: {
    Paginator,
  },
  data() {
    return {
      totalPages: null,
      currentPage: 1,
    }
  },
  methods: {
    setPages(data) {
      if (data) {
        this.currentPage = data.currentPage
        this.totalPages = data.totalPages
      } else {
        this.currentPage = 1
        this.totalPages = null
      }
    },
  },
}
