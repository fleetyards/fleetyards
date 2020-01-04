<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 v-if="celestialObject">
          {{ celestialObject.name }}
          <small>{{ celestialObject.designation }}</small>
        </h1>
      </div>
    </div>
    <div
      v-if="celestialObject"
      class="row"
    >
      <div class="col-xs-12 col-md-8">
        <blockquote
          v-if="celestialObject.description"
          class="description"
        >
          <p v-html="celestialObject.description" />
        </blockquote>
      </div>
      <div class="col-xs-12 col-md-4">
        <Panel>
          <CelestialObjectMetrics
            :celestial-object="celestialObject"
            padding
          />
        </Panel>
      </div>
    </div>
    <div class="row">
      <div
        v-if="celestialObject && celestialObject.moons.length"
        class="col-xs-12"
      >
        <h2>{{ $t('headlines.moons') }}</h2>
        <transition-group
          name="fade-list"
          class="flex-row"
          tag="div"
          appear
        >
          <div
            v-for="moon in celestialObject.moons"
            :key="moon.slug"
            class="col-xs-12 col-sm-6 col-md-3 fade-list-item"
          >
            <ItemPanel
              :item="moon"
              :route="{
                name: 'celestial-object',
                params: {
                  starsystem: celestialObject.starsystem.slug,
                  slug: moon.slug,
                },
              }"
            />
          </div>
        </transition-group>
      </div>
    </div>
    <div
      v-if="celestialObject && stations.length"
      class="row"
    >
      <div class="col-xs-12 col-md-6">
        <h2>{{ $t('headlines.stations') }}</h2>
      </div>
      <div class="col-xs-12 col-md-6">
        <Paginator
          v-if="stations.length"
          :page="currentPage"
          :total="totalPages"
          right
        />
      </div>
      <div class="col-xs-12">
        <transition-group
          name="fade-list"
          class="flex-row"
          tag="div"
          appear
        >
          <div
            v-for="station in stations"
            :key="station.slug"
            class="col-xs-12 fade-list-item"
          >
            <StationPanel :station="station" />
          </div>
        </transition-group>
        <Loader
          :loading="loading"
          fixed
        />
      </div>
      <div class="col-xs-12">
        <Paginator
          v-if="stations.length"
          :page="currentPage"
          :total="totalPages"
          right
        />
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'
import StationPanel from 'frontend/components/Stations/Panel'
import ItemPanel from 'frontend/partials/Stations/Panel'
import Hash from 'frontend/mixins/Hash'
import Pagination from 'frontend/mixins/Pagination'
import BreadCrumbs from 'frontend/components/BreadCrumbs'
import CelestialObjectMetrics from 'frontend/partials/CelestialObjects/Metrics'

export default {
  components: {
    Loader,
    Panel,
    StationPanel,
    ItemPanel,
    CelestialObjectMetrics,
    BreadCrumbs,
  },

  mixins: [
    MetaInfo,
    Hash,
    Pagination,
  ],

  data() {
    return {
      loading: false,
      celestialObject: null,
      stations: [],
    }
  },

  computed: {
    metaTitle() {
      if (!this.celestialObject) {
        return null
      }

      return this.$t('title.celestialObject', { celestialObject: this.celestialObject.name, starsystem: this.celestialObject.starsystem.name })
    },

    crumbs() {
      if (!this.celestialObject) {
        return null
      }

      const crumbs = [{
        to: {
          name: 'starsystems',
          hash: `#${this.celestialObject.starsystem.slug}`,
        },
        label: this.$t('nav.starsystems'),
      }, {
        to: {
          name: 'starsystem',
          params: {
            slug: this.celestialObject.starsystem.slug,
          },
          hash: `#${this.celestialObject.slug}`,
        },
        label: this.celestialObject.starsystem.name,
      }]

      if (this.celestialObject.parent) {
        crumbs.push({
          to: {
            name: 'celestial-object',
            params: {
              starsystem: this.celestialObject.starsystem.slug,
              slug: this.celestialObject.parent.slug,
            },
          },
          label: this.celestialObject.parent.name,
        })
      }

      return crumbs
    },
  },

  watch: {
    $route() {
      this.fetch()
    },

    celestialObject() {
      if (this.celestialObject.storeImage) {
        this.$store.commit('setBackgroundImage', this.celestialObject.storeImage)
      }
    },
  },

  created() {
    this.fetch()
  },

  methods: {
    async fetch() {
      this.loading = true
      const response = await this.$api.get(`celestial-objects/${this.$route.params.slug}`)
      this.loading = false
      if (!response.error) {
        this.celestialObject = response.data
        this.fetchStations()
      }
    },

    async fetchStations() {
      this.loading = true
      const response = await this.$api.get('stations', {
        q: {
          ...this.$route.query.q,
          celestialObjectEq: this.$route.params.slug,
          sorts: ['station_type asc', 'name asc'],
        },
        page: this.$route.query.page,
      })

      this.loading = false
      if (!response.error) {
        this.stations = response.data
        this.scrollToAnchor()
      }

      this.setPages(response.meta)
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
