<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1
          v-if="shop"
          class="back-button"
        >
          {{ shop.name }}
          <small>
            {{ shop.station.name }}
          </small>
          <router-link
            :to="{
              name: 'station',
              params: {
                slug: shop.station.slug,
              },
              hash: `#${shop.slug}`,
            }"
            class="btn btn-link"
          >
            <i class="fal fa-chevron-left" />
          </router-link>
        </h1>
      </div>
    </div>
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import Hash from 'frontend/mixins/Hash'

export default {
  components: {
    Loader,
  },
  mixins: [I18n, MetaInfo, Hash],
  data() {
    return {
      loading: false,
      shop: null,
    }
  },
  computed: {
    title() {
      if (!this.shop) {
        return ''
      }
      return this.t('title.shop', { shop: this.shop.name, station: this.shop.station.name })
    },
  },
  watch: {
    $route() {
      this.fetch()
    },
  },
  created() {
    this.fetch()
  },
  methods: {
    async fetch() {
      this.loading = true
      const response = await this.$api.get(`stations/${this.$route.params.station}/shops/${this.$route.params.slug}`)
      this.loading = false
      if (!response.error) {
        this.shop = response.data
      }
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.title,
    })
  },
}
</script>

<style>

</style>
