<template>
  <section class="container">
    <div class="row">
      <div class="col-12 col-md-8">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 v-if="station">
          {{ station.name }}
        </h1>
      </div>
      <div class="col-12 col-md-4">
        <div class="page-actions page-actions-right">
          <PriceModalBtn
            v-if="station && station.shops.length"
            :station-slug="station.slug"
          />
        </div>
      </div>
    </div>
    <div class="row">
      <div v-if="station" class="col-12 col-lg-8">
        <img :src="station.storeImage" class="image" alt="model image" />
        <blockquote v-if="station.description" class="description">
          <p v-html="station.description" />
        </blockquote>
      </div>
      <div v-if="station" class="col-12 col-lg-4">
        <Panel>
          <StationBaseMetrics :station="station" :padding="true" />
          <StationDocks :station="station" :padding="true" />
          <StationHabitations :station="station" :padding="true" />
        </Panel>
        <div class="text-right">
          <div class="page-actions page-actions-right">
            <Btn
              v-if="station.hasImages"
              :to="{ name: 'station-images', params: { slug: station.slug } }"
            >
              <i class="fa fa-images" />
            </Btn>
          </div>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <template v-if="station && station.shops.length">
          <h2>{{ $t('headlines.shops') }}</h2>
          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="shop in station.shops"
              :key="shop.slug"
              class="col-12 col-lg-3 fade-list-item"
            >
              <ShopPanel
                :item="shop"
                :route="{
                  name: 'shop',
                  params: {
                    stationSlug: station.slug,
                    slug: shop.slug,
                  },
                }"
              />
            </div>
          </transition-group>
          <Loader :loading="loading" fixed />
        </template>
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from '@/frontend/mixins/MetaInfo'
import Loader from '@/frontend/core/components/Loader/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import PriceModalBtn from '@/frontend/components/ShopCommodities/PriceModalBtn/index.vue'
import Panel from '@/frontend/core/components/Panel/index.vue'
import ShopPanel from '@/frontend/components/Stations/Item/index.vue'
import StationBaseMetrics from '@/frontend/components/Stations/BaseMetrics/index.vue'
import StationDocks from '@/frontend/components/Stations/Docks/index.vue'
import StationHabitations from '@/frontend/components/Stations/Habitations/index.vue'
import BreadCrumbs from '@/frontend/core/components/BreadCrumbs/index.vue'
import { stationRouteGuard } from '@/frontend/utils/RouteGuards/Stations'
import stationsCollection from '@/frontend/api/collections/Stations'

export default {
  name: 'StationDetail',
  components: {
    BreadCrumbs,
    Btn,
    Loader,
    Panel,
    PriceModalBtn,
    ShopPanel,
    StationBaseMetrics,
    StationDocks,
    StationHabitations,
  },

  mixins: [MetaInfo],

  beforeRouteEnter: stationRouteGuard,

  data() {
    return {
      loading: false,
    }
  },

  computed: {
    crumbs() {
      if (!this.station) {
        return null
      }

      const crumbs = [
        {
          label: this.$t('nav.starsystems'),
          to: {
            hash: `#${this.station.celestialObject.starsystem.slug}`,
            name: 'starsystems',
          },
        },
        {
          label: this.station.celestialObject.starsystem.name,
          to: {
            hash: `#${this.station.celestialObject.slug}`,
            name: 'starsystem',
            params: {
              slug: this.station.celestialObject.starsystem.slug,
            },
          },
        },
      ]

      if (this.station.celestialObject.parent) {
        crumbs.push({
          label: this.station.celestialObject.parent.name,
          to: {
            name: 'celestial-object',
            params: {
              slug: this.station.celestialObject.parent.slug,
              starsystem: this.station.celestialObject.starsystem.slug,
            },
          },
        })
      }

      crumbs.push({
        label: this.station.celestialObject.name,
        to: {
          hash: `#${this.station.slug}`,
          name: 'celestial-object',
          params: {
            slug: this.station.celestialObject.slug,
            starsystem: this.station.celestialObject.starsystem.slug,
          },
        },
      })

      return crumbs
    },

    metaTitle() {
      if (!this.station) {
        return null
      }

      return this.$t('title.station', {
        celestialObject: this.station.celestialObject.name,
        station: this.station.name,
      })
    },

    station() {
      return stationsCollection.record
    },
  },

  mounted() {
    this.fetch()
  },

  methods: {
    async fetch() {
      this.loading = true
      await stationsCollection.findBySlug(this.$route.params.slug)
      this.loading = false
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
