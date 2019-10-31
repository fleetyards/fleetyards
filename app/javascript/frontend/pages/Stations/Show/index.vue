<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1 v-if="station">
          <router-link
            :to="backRoute"
            class="back-button"
          >
            <i class="fal fa-chevron-left" />
          </router-link>
          {{ station.name }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div
        v-if="station"
        class="col-xs-12 col-md-8"
      >
        <img
          :src="station.storeImage"
          class="image"
          alt="model image"
        >
        <blockquote
          v-if="station.description"
          class="description"
        >
          <p v-html="station.description" />
        </blockquote>
      </div>
      <div
        v-if="station"
        class="col-xs-12 col-md-4"
      >
        <Panel>
          <StationBaseMetrics
            :station="station"
            padding
          />
          <StationDocks
            :station="station"
            padding
          />
          <StationHabitations
            :station="station"
            padding
          />
        </Panel>
        <div class="text-right">
          <div class="page-actions">
            <Btn
              v-if="station.hasImages"
              :to="{ name: 'station-images', params: { slug: station.slug }}"
            >
              <i class="fa fa-images" />
            </Btn>
          </div>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <template v-if="station && station.shops.length">
          <h2>{{ $t('headlines.shops') }}</h2>
          <transition-group
            name="fade-list"
            class="flex-row"
            tag="div"
            appear
          >
            <div
              v-for="shop in station.shops"
              :key="shop.slug"
              class="col-xs-12 col-md-3 fade-list-item"
            >
              <ShopPanel
                :item="shop"
                :route="{
                  name: 'shop',
                  params: {
                    station: station.slug,
                    slug: shop.slug,
                  },
                }"
              />
            </div>
          </transition-group>
          <Loader
            :loading="loading"
            fixed
          />
        </template>
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import Btn from 'frontend/components/Btn'
import Hash from 'frontend/mixins/Hash'
import Panel from 'frontend/components/Panel'
import ShopPanel from 'frontend/partials/Stations/Panel'
import StationBaseMetrics from 'frontend/partials/Stations/BaseMetrics'
import StationDocks from 'frontend/partials/Stations/Docks'
import StationHabitations from 'frontend/partials/Stations/Habitations'
import { mapGetters } from 'vuex'

export default {
  name: 'Station',

  components: {
    Loader,
    Btn,
    Panel,
    ShopPanel,
    StationBaseMetrics,
    StationDocks,
    StationHabitations,
  },

  mixins: [
    MetaInfo,
    Hash,
  ],

  data() {
    return {
      loading: false,
      station: null,
    }
  },

  computed: {
    ...mapGetters([
      'previousRoute',
    ]),

    ...mapGetters('stations', [
      'backRoute',
    ]),

    metaTitle() {
      if (!this.station) {
        return null
      }

      return this.$t('title.station', { station: this.station.name, celestialObject: this.station.celestialObject.name })
    },
  },

  watch: {
    $route() {
      this.fetch()
    },

    station() {
      this.setBackRoute()

      if (this.station.backgroundImage) {
        this.$store.commit('setBackgroundImage', this.station.backgroundImage)
      }
    },
  },

  created() {
    this.fetch()
  },

  methods: {
    setBackRoute() {
      const route = {
        name: 'stations',
        hash: `#${this.station.slug}`,
      }

      if (this.previousRoute && ['stations', 'celestialObject'].includes(this.previousRoute.name)) {
        route.name = this.previousRoute.name
        route.params = this.previousRoute.params
        route.query = this.previousRoute.query
      }

      this.$store.commit('stations/setBackRoute', route)
    },

    async fetch() {
      this.loading = true
      const response = await this.$api.get(`stations/${this.$route.params.slug}`)
      this.loading = false
      if (!response.error) {
        this.station = response.data
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
