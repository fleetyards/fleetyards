<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1 v-if="starsystem">
          <router-link
            :to="{name: 'starsystems'}"
            class="back-button"
          >
            <i class="fal fa-chevron-left" />
          </router-link>
          {{ $t('headlines.starsystem', { starsystem: starsystem.name }) }}
        </h1>
      </div>
    </div>
    <div
      v-if="starsystem"
      class="row"
    >
      <div class="col-xs-12 col-md-8">
        <blockquote
          v-if="starsystem.description"
          class="description"
        >
          <p v-html="starsystem.description" />
        </blockquote>
      </div>
      <div class="col-xs-12 col-md-4">
        <Panel>
          <ul class="list-group metrics">
            <li class="list-group-item">
              <StarsystemBaseMetrics :starsystem="starsystem" />
            </li>
            <li class="list-group-item">
              <StarsystemLevelsMetrics :starsystem="starsystem" />
            </li>
          </ul>
        </Panel>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <Paginator
          v-if="celestialObjects.length"
          :page="currentPage"
          :total="totalPages"
          right
        />
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <transition-group
          name="fade-list"
          class="flex-row"
          tag="div"
          appear
        >
          <div
            v-for="celestialObject in celestialObjects"
            :key="celestialObject.slug"
            class="col-xs-12 fade-list-item"
          >
            <PlanetList
              :item="celestialObject"
              :route="{
                name: 'celestialObject',
                params: {
                  slug: celestialObject.slug,
                },
              }"
            >
              <template v-if="celestialObject.moons.length">
                <h3 class="sr-only">
                  {{ $t('headlines.celestialObjects') }}
                </h3>
                <transition-group
                  name="fade-list"
                  class="flex-row"
                  tag="div"
                  appear
                >
                  <div
                    v-for="moon in celestialObject.moons"
                    :key="moon.slug"
                    class="col-xs-12 col-md-3 fade-list-item"
                  >
                    <MoonPanel
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
              </template>
            </PlanetList>
          </div>
        </transition-group>
        <EmptyBox v-if="emptyBoxVisible" />
        <Loader
          :loading="loading"
          fixed
        />
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <Paginator
          v-if="celestialObjects.length"
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
import PlanetList from 'frontend/partials/Planets/List'
import MoonPanel from 'frontend/partials/Planets/Panel'
import EmptyBox from 'frontend/partials/EmptyBox'
import StarsystemBaseMetrics from 'frontend/partials/Starsystems/BaseMetrics'
import StarsystemLevelsMetrics from 'frontend/partials/Starsystems/LevelsMetrics'
import Hash from 'frontend/mixins/Hash'
import Pagination from 'frontend/mixins/Pagination'

export default {
  name: 'Starsystem',

  components: {
    Loader,
    EmptyBox,
    PlanetList,
    MoonPanel,
    StarsystemBaseMetrics,
    StarsystemLevelsMetrics,
    Panel,
  },

  mixins: [
    MetaInfo,
    Hash,
    Pagination,
  ],

  data() {
    return {
      loading: false,
      starsystem: null,
      celestialObjects: [],
    }
  },

  computed: {
    emptyBoxVisible() {
      return !this.loading && !this.celestialObjects.length
    },

    starsystemName() {
      if (this.celestialObjects.length === 0) {
        return ''
      }
      return this.celestialObjects[0].starsystem.name
    },

    metaTitle() {
      if (!this.starsystem) {
        return null
      }
      return this.$t('title.starsystem', { starsystem: this.starsystem.name })
    },
  },

  watch: {
    $route() {
      this.fetchCelestialObjects()
    },

    starsystem() {
      if (this.starsystem.storeImage) {
        this.$store.commit('setBackgroundImage', this.starsystem.storeImage)
      }
    },
  },

  created() {
    this.fetch()
    this.fetchCelestialObjects()
  },

  methods: {
    async fetch() {
      const response = await this.$api.get(`starsystems/${this.$route.params.slug}`)
      if (!response.error) {
        this.starsystem = response.data
      }
    },

    async fetchCelestialObjects() {
      this.loading = true
      const response = await this.$api.get('celestial-objects', {
        q: {
          ...this.$route.query.q,
          starsystemEq: this.$route.params.slug,
          main: true,
        },
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.celestialObjects = response.data
        this.scrollToAnchor()
      }
      this.setPages(response.meta)
    },
  },
}
</script>
