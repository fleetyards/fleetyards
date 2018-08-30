import I18n from 'frontend/mixins/I18n'

export default {
  mixins: [I18n],
  methods: {
    getMetaInfo(tags) {
      return {
        title: this.getMetaTitle(tags.title),
      }
    },
    getMetaTitle(title) {
      if (!title) {
        return this.t('app')
      }
      return this.t('title.main', { title })
    },
  },
}
