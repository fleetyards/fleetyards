<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1
          v-if="station"
          class="back-button"
        >
          {{ station.name }}
          <router-link
            :to="{
              name: 'planet',
              params: {
                slug: station.planet.slug,
              },
              hash: `#${station.slug}`,
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
import EmptyBox from 'frontend/partials/EmptyBox'
import Hash from 'frontend/mixins/Hash'

export default {
  components: {
    Loader,
    EmptyBox,
  },
  mixins: [I18n, MetaInfo, Hash],
  data() {
    return {
      loading: false,
      station: null,
    }
  },
  computed: {
    emptyBoxVisible() {
      return !this.loading && (!this.station || this.station.shops.length === 0)
    },
    title() {
      if (!this.station) {
        return null
      }
      return this.t('title.station', { station: this.station.name, planet: this.station.planet.name })
    },
  },
  watch: {
    $route() {
      this.fetch()
    },
    station() {
      if (this.station.storeImage) {
        this.$store.commit('setBackgroundImage', this.station.storeImage)
      }
    },
  },
  created() {
    this.fetch()
  },
  methods: {
    async fetch() {
      this.loading = true
      const response = await this.$api.get(`stations/${this.$route.params.slug}`)
      this.loading = false
      if (!response.error) {
        this.station = response.data
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
