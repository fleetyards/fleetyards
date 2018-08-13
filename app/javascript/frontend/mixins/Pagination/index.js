import Paginator from 'frontend/components/Paginator'

export default {
  components: {
    Paginator,
  },
  data() {
    return {
      totalPages: null,
      currentPage: null,
    }
  },
  methods: {
    setPages(data) {
      if (data) {
        this.currentPage = data.currentPage
        this.totalPages = data.totalPages
      } else {
        this.currentPage = null
        this.totalPages = null
      }
    },
  },
}
