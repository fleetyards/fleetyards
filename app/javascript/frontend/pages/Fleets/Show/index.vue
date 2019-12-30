<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 v-if="fleet">
          {{ fleet.name }}
        </h1>
      </div>
    </div>
    <div class="row">
      {{ fleet }}
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
// import Loader from 'frontend/components/Loader'
// import Btn from 'frontend/components/Btn'
import Hash from 'frontend/mixins/Hash'
import BreadCrumbs from 'frontend/components/BreadCrumbs'

export default {
  name: 'Fleet',

  components: {
    // Loader,
    // Btn,
    BreadCrumbs,
  },

  mixins: [
    MetaInfo,
    Hash,
  ],

  data() {
    return {
      loading: false,
      fleet: null,
    }
  },

  computed: {
    metaTitle() {
      if (!this.fleet) {
        return null
      }

      return this.$t('title.fleet', { fleet: this.fleet.name })
    },

    crumbs() {
      let hash = ''
      if (this.fleet) {
        hash = `#${this.fleet.slug}`
      }
      return [{
        to: {
          name: 'fleets',
          hash,
        },
        label: this.$t('nav.fleets.index'),
      }]
    },
  },

  watch: {
    $route() {
      this.fetch()
    },

    fleet() {
      if (this.fleet.backgroundImage) {
        this.$store.commit('setBackgroundImage', this.fleet.backgroundImage)
      }
    },
  },

  mounted() {
    this.fetch()
  },

  methods: {
    async fetch() {
      this.loading = true

      const response = await this.$api.get(`fleets/${this.$route.params.slug}`)

      this.loading = false

      if (!response.error) {
        this.fleet = response.data
      }
    },
  },
}
</script>
