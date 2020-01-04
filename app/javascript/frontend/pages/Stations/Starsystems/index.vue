<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1 class="sr-only">
          {{ $t('headlines.starsystems') }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <Panel>
          <div class="starmap">
            <img
              :src="require('images/map.png')"
              alt="map"
            >
            <router-link
              v-for="starsystem in starsystems"
              :key="starsystem.slug"
              :to="{
                name: 'starsystem',
                params: {
                  slug: starsystem.slug,
                },
              }"
              :style="{
                left: `${starsystem.mapX}%`,
                top: `${starsystem.mapY}%`
              }"
              class="starsystem"
            />
          </div>
        </Panel>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <Paginator
          v-if="starsystems.length"
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
            v-for="starsystem in starsystems"
            :key="starsystem.slug"
            class="col-xs-12 fade-list-item"
          >
            <StarsystemList
              :item="starsystem"
              :route="{
                name: 'starsystem',
                params: {
                  slug: starsystem.slug,
                },
              }"
            >
              <template v-if="starsystem.celestialObjects.length">
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
                    v-for="celestialObject in starsystem.celestialObjects"
                    :key="celestialObject.slug"
                    class="col-xs-12 col-md-3 fade-list-item"
                  >
                    <PlanetPanel
                      :item="celestialObject"
                      :route="{
                        name: 'celestial-object',
                        params: {
                          starsystem: celestialObject.starsystem.slug,
                          slug: celestialObject.slug,
                        },
                      }"
                    />
                  </div>
                </transition-group>
              </template>
            </StarsystemList>
          </div>
        </transition-group>
        <Loader
          :loading="loading"
          fixed
        />
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <Paginator
          v-if="starsystems.length"
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
import StarsystemList from 'frontend/partials/Starsystems/List'
import PlanetPanel from 'frontend/partials/Planets/Panel'
import Hash from 'frontend/mixins/Hash'
import Pagination from 'frontend/mixins/Pagination'

export default {
  name: 'Starsystems',

  components: {
    Loader,
    Panel,
    StarsystemList,
    PlanetPanel,
  },

  mixins: [
    MetaInfo,
    Hash,
    Pagination,
  ],

  data() {
    return {
      loading: false,
      starsystems: [],
    }
  },

  watch: {
    $route() {
      this.fetch()
    },
  },

  created() {
    this.fetch()
  },

  methods: {
    async fetch() {
      this.loading = true
      const response = await this.$api.get('starsystems', {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.starsystems = response.data
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
