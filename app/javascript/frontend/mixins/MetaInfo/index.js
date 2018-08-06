import I18n from 'frontend/mixins/I18n'

export default {
  mixins: [I18n],
  methods: {
    getMetaInfo(tags) {
      return {
        title: this.getMetaTitle(tags.title),
        meta: [
          this.getMetaDescription(tags.description),
          this.getMetaKeywords(tags.keywords),
          this.getMetaOgType(tags.ogType),
          this.getMetaOgTitle(tags.title),
          this.getMetaOgUrl(tags.url),
          this.getMetaOgImage(tags.ogImage),
        ],
      }
    },
    getMetaTitle(title) {
      if (!title) {
        return this.t('app')
      }
      return this.t('title.main', { title })
    },
    getMetaDescription(description = this.t('meta.description')) {
      return this.getMetaTag('discription', description)
    },
    getMetaKeywords(keywords = this.t('meta.keywords')) {
      return this.getMetaTag('keywords', keywords)
    },
    getMetaOgType(type) {
      return this.getMetaTag('og:type', type)
    },
    getMetaOgTitle(title) {
      return this.getMetaTag('og:title', this.getMetaTitle(title))
    },
    getMetaOgUrl(url = `https://www.fleetyards.net${this.$route.fullPath}`) {
      return this.getMetaTag('og:url', url)
    },
    getMetaOgImage(image) {
      return this.getMetaTag('og:image', image)
    },
    getMetaTag(property, content) {
      if (!content) {
        return {}
      }
      return { property, content }
    },
  },
}
