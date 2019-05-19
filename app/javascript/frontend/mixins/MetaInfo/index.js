export default {
  methods: {
    getMetaInfo(tags) {
      return {
        title: this.getMetaTitle(tags.title),
      }
    },
    getMetaTitle(title) {
      if (!title) {
        return this.$t('app')
      }
      return this.$t('title.main', { title })
    },
  },
}
