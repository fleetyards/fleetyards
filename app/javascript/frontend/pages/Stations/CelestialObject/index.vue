<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1 v-if="celestialObject">
          <router-link
            :to="{
              name: 'starsystem',
              params: {
                slug: celestialObject.starsystem.slug,
              },
              hash: `#${celestialObject.slug}`,
            }"
            class="back-button"
          >
            <i class="fal fa-chevron-left" />
          </router-link>
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
          <ul class="list-group">
            <li class="list-group-item">
              <CelestialObjectMetrics :celestial-object="celestialObject" />
            </li>
          </ul>
        </Panel>
      </div>
    </div>
    <div class="row">
      <div
        v-if="celestialObject && celestialObject.moons.length"
        class="col-xs-12"
      >
        <h2>{{ t('headlines.moons') }}</h2>
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
            <ShopPanel
              :item="moon"
              :route="{
                name: 'celestialObject',
                params: {
                  slug: moon.slug,
                },
              }"
            />
          </div>
        </transition-group>
      </div>
    </div>
    <div
      v-if="celestialObject"
      class="row"
    >
      <div class="col-xs-12 col-md-6">
        <h2>{{ t('headlines.stations') }}</h2>
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
            <StationList
              :item="station"
              :route="{
                name: 'station',
                params: {
                  slug: station.slug
                }
              }"
            >
              <template slot="stats">
                <dl class="dl-horizontal">
                  <dt>{{ t('labels.station.type') }}:</dt>
                  <dd>{{ station.typeLabel }}</dd>
                  <dt>{{ t('labels.station.location') }}:</dt>
                  <dd>{{ station.location }}</dd>
                  <dt>{{ t('labels.station.docks') }}:</dt>
                  <dd>
                    <template v-if="station.docks.length">
                      <ul class="list-unstyled">
                        <li
                          v-for="(dock, index) in station.docks"
                          :key="index"
                        >
                          {{ dock.size }} {{ dock.typeLabel }}: {{ dock.count }}
                        </li>
                      </ul>
                    </template>
                    <template v-else>
                      {{ t('labels.none') }}
                    </template>
                  </dd>

                  <dt>{{ t('labels.station.habitation') }}:</dt>
                  <dd>
                    <template v-if="station.habitations.length">
                      <ul class="list-unstyled">
                        <li
                          v-for="(habitation, index) in station.habitations"
                          :key="index"
                        >
                          {{ habitation.typeLabel }}: {{ habitation.count }}
                        </li>
                      </ul>
                    </template>
                    <template v-else>
                      {{ t('labels.none') }}
                    </template>
                  </dd>
                </dl>
              </template>
              <template v-if="station.shops.length">
                <h3>{{ t('headlines.shops') }}</h3>
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
                      :id="`${station.slug}-${shop.slug}`"
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
              </template>
            </StationList>
          </div>
        </transition-group>
        <EmptyBox v-if="emptyBoxVisible" />
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
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'
import StationList from 'frontend/partials/Stations/List'
import ShopPanel from 'frontend/partials/Stations/Panel'
import EmptyBox from 'frontend/partials/EmptyBox'
import Hash from 'frontend/mixins/Hash'
import Pagination from 'frontend/mixins/Pagination'
import CelestialObjectMetrics from 'frontend/partials/CelestialObjects/Metrics'

export default {
  components: {
    Loader,
    Panel,
    EmptyBox,
    StationList,
    ShopPanel,
    CelestialObjectMetrics,
  },
  mixins: [I18n, MetaInfo, Hash, Pagination],
  data() {
    return {
      loading: false,
      celestialObject: null,
      stations: [],
    }
  },
  computed: {
    emptyBoxVisible() {
      return !this.loading && this.stations.length === 0
    },
    title() {
      if (!this.celestialObject) {
        return null
      }
      return this.t('title.celestialObject', { celestialObject: this.celestialObject.name, starsystem: this.celestialObject.starsystem.name })
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
  metaInfo() {
    return this.getMetaInfo({
      title: this.title,
    })
  },
}
</script>

<style lang="scss" scoped>
  @import './styles/index.scss';
</style>
