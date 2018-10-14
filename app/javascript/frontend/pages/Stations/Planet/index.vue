<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1
          v-if="planet"
          class="back-button"
        >
          {{ planet.name }}
          <router-link
            :to="{
              name: 'starsystem',
              params: {
                slug: planet.starsystem.slug,
              },
              hash: `#${planet.slug}`,
            }"
            class="btn btn-link"
          >
            <i class="fal fa-chevron-left" />
          </router-link>
        </h1>
      </div>
    </div>
    <div
      v-if="planet"
      class="row"
    >
      <div class="col-xs-12">
        <h2 class="sr-only">{{ t('headlines.stations') }}</h2>
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
                  <dt>{{ t('labels.stations.type') }}:</dt>
                  <dd>{{ station.typeLabel }}</dd>
                  <dt>{{ t('labels.stations.location') }}:</dt>
                  <dd>{{ station.location }}</dd>
                  <dt>{{ t('labels.stations.docks') }}:</dt>
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

                  <dt>{{ t('labels.stations.habitation') }}:</dt>
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
      <div
        v-if="planet.moons.length"
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
            v-for="moon in planet.moons"
            :key="moon.slug"
            class="col-xs-12 col-sm-6 col-md-3 fade-list-item"
          >
            <ShopPanel
              :item="moon"
              :route="{
                name: 'planet',
                params: {
                  slug: moon.slug,
                },
              }"
            />
          </div>
        </transition-group>
      </div>
    </div>
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import StationList from 'frontend/partials/Stations/List'
import ShopPanel from 'frontend/partials/Stations/Panel'
import EmptyBox from 'frontend/partials/EmptyBox'
import Hash from 'frontend/mixins/Hash'

export default {
  components: {
    Loader,
    EmptyBox,
    StationList,
    ShopPanel,
  },
  mixins: [I18n, MetaInfo, Hash],
  data() {
    return {
      loading: false,
      planet: null,
      stations: [],
    }
  },
  computed: {
    emptyBoxVisible() {
      return !this.loading && this.stations.length === 0
    },
    title() {
      if (!this.planet) {
        return null
      }
      return this.t('title.planet', { planet: this.planet.name, starsystem: this.planet.starsystem.name })
    },
  },
  watch: {
    $route() {
      this.fetch()
    },
    planet() {
      if (this.planet.storeImage) {
        this.$store.commit('setBackgroundImage', this.planet.storeImage)
      }
    },
  },
  created() {
    this.fetch()
  },
  methods: {
    async fetch() {
      this.loading = true
      const response = await this.$api.get(`planets/${this.$route.params.slug}`)
      this.loading = false
      if (!response.error) {
        this.planet = response.data
        this.fetchStations()
      }
    },
    async fetchStations() {
      this.loading = true
      const response = await this.$api.get('stations', {
        q: {
          ...this.$route.query.q,
          planetSlugEq: this.$route.params.slug,
        },
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.stations = response.data
        this.scrollToAnchor()
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

<style lang="scss" scoped>
  @import './styles/index.scss';
</style>
