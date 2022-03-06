import Paginator from '@/frontend/core/components/Paginator/index.vue'

export default {
  components: {
    Paginator,
  },

  data() {
    return {
      currentPage: 1,
      totalPages: null,
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
