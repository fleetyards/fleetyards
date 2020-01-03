<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 v-if="station">
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
import BreadCrumbs from 'frontend/components/BreadCrumbs'

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
    BreadCrumbs,
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
    metaTitle() {
      if (!this.station) {
        return null
      }

      return this.$t('title.station', { station: this.station.name, celestialObject: this.station.celestialObject.name })
    },

    crumbs() {
      if (!this.station) {
        return null
      }

      const crumbs = [{
        to: {
          name: 'starsystems',
          hash: `#${this.station.celestialObject.starsystem.slug}`,
        },
        label: this.$t('nav.starsystems'),
      }, {
        to: {
          name: 'starsystem',
          params: {
            slug: this.station.celestialObject.starsystem.slug,
          },
          hash: `#${this.station.celestialObject.slug}`,
        },
        label: this.station.celestialObject.starsystem.name,
      }]

      if (this.station.celestialObject.parent) {
        crumbs.push({
          to: {
            name: 'celestial-object',
            params: {
              starsystem: this.station.celestialObject.starsystem.slug,
              slug: this.station.celestialObject.parent.slug,
            },
          },
          label: this.station.celestialObject.parent.name,
        })
      }

      crumbs.push({
        to: {
          name: 'celestial-object',
          params: {
            starsystem: this.station.celestialObject.starsystem.slug,
            slug: this.station.celestialObject.slug,
          },
          hash: `#${this.station.slug}`,
        },
        label: this.station.celestialObject.name,
      })

      return crumbs
    },
  },

  watch: {
    $route() {
      this.fetch()
    },

    station() {
      if (this.station.backgroundImage) {
        this.$store.commit('setBackgroundImage', this.station.backgroundImage)
      }
    },
  },

  mounted() {
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
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
