<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1
          v-if="starsystem"
          class="back-button"
        >
          {{ t('headlines.starsystem', { starsystem: starsystem.name }) }}
          <router-link
            :to="{name: 'starsystems'}"
            class="btn btn-link"
          >
            <i class="fal fa-chevron-left" />
          </router-link>
        </h1>
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
            v-for="planet in planets"
            :key="planet.slug"
            class="col-xs-12 fade-list-item"
          >
            <PlanetList
              :item="planet"
              :route="{
                name: 'planet',
                params: {
                  slug: planet.slug,
                },
              }"
            >
              <template v-if="planet.moons.length">
                <h3>{{ t('headlines.moons') }}</h3>
                <transition-group
                  name="fade-list"
                  class="flex-row"
                  tag="div"
                  appear
                >
                  <div
                    v-for="moon in planet.moons"
                    :key="moon.slug"
                    class="col-xs-12 col-md-3 fade-list-item"
                  >
                    <MoonPanel
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
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import PlanetList from 'frontend/partials/Stations/List'
import MoonPanel from 'frontend/partials/Stations/Panel'
import EmptyBox from 'frontend/partials/EmptyBox'
import Hash from 'frontend/mixins/Hash'

export default {
  components: {
    Loader,
    EmptyBox,
    PlanetList,
    MoonPanel,
  },
  mixins: [I18n, MetaInfo, Hash],
  data() {
    return {
      loading: false,
      starsystem: null,
      planets: [],
    }
  },
  computed: {
    emptyBoxVisible() {
      return !this.loading && !this.planets.length
    },
    starsystemName() {
      if (this.planets.length === 0) {
        return ''
      }
      return this.planets[0].starsystem.name
    },
    title() {
      if (!this.starsystem) {
        return null
      }
      return this.t('title.starsystem', { starsystem: this.starsystem.name })
    },
  },
  watch: {
    $route() {
      this.fetchPlanets()
    },
    starsystem() {
      if (this.starsystem.storeImage) {
        this.$store.commit('setBackgroundImage', this.starsystem.storeImage)
      }
    },
  },
  created() {
    this.fetch()
    this.fetchPlanets()
  },
  methods: {
    async fetch() {
      const response = await this.$api.get(`starsystems/${this.$route.params.slug}`)
      if (!response.error) {
        this.starsystem = response.data
      }
    },
    async fetchPlanets() {
      this.loading = true
      const response = await this.$api.get('planets', {
        q: {
          ...this.$route.query.q,
          starsystemSlugEq: this.$route.params.slug,
        },
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.planets = response.data
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
