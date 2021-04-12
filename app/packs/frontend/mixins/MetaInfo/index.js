export default {
  computed: {
    metaTitle() {
      const { title } = this.$route.meta
      if (title) {
        return this.$t(`title.${title}`)
      }

      return null
    },
  },

  head() {
    return {
      title: this.metaTitle,
      titleTemplate(title) {
        if (title) {
          return `${title} | ${this.$t('app')}`
        }

        return this.$t('app')
      },
    }
  },
}
