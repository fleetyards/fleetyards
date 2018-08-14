export default {
  methods: {
    scrollToAnchor() {
      if (!this.$route.hash) {
        return
      }
      this.$nextTick(() => {
        const element = document.getElementById(this.$route.hash.slice(1))
        if (element) {
          element.scrollIntoView()
          window.scrollBy(0, -120)
        }
      })
    },
  },
}
