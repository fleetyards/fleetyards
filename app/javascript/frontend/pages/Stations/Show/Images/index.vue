<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <BreadCrumbs :crumbs="crumbs" />
            <h1>
              {{ metaTitle }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12">
            <Paginator
              v-if="images.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>
        <transition-group
          v-if="images"
          name="fade-list"
          class="flex-row flex-center images"
          tag="div"
          appear
        >
          <div
            v-for="(image, index) in images"
            :key="image.id"
            class="col-xs-12 col-ms-6 col-sm-6 col-md-4 col-xxlg-2-4 fade-list-item"
          >
            <GalleryImage
              :src="image.smallUrl"
              :href="image.url"
              :alt="image.name"
              @click.native.prevent.exact="openGallery(index)"
            />
          </div>
        </transition-group>
        <div class="row">
          <div class="col-xs-12">
            <Paginator
              v-if="images.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>
        <Loader :loading="loading" />
      </div>
    </div>

    <Gallery
      ref="gallery"
      :items="images"
    />
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Pagination from 'frontend/mixins/Pagination'
import Loader from 'frontend/components/Loader'
import GalleryHelpers from 'frontend/mixins/GalleryHelpers'
import BreadCrumbs from 'frontend/components/BreadCrumbs'

export default {
  components: {
    Loader,
    BreadCrumbs,
  },

  mixins: [
    GalleryHelpers,
    MetaInfo,
    Pagination,
  ],

  data() {
    return {
      images: [],
      station: null,
      loading: false,
    }
  },

  computed: {
    metaTitle() {
      if (!this.station) {
        return null
      }

      return this.$t('title.stationImages', { station: this.station.name, celestialObject: this.station.celestialObject.name })
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

      crumbs.push({
        to: {
          name: 'station',
          params: {
            slug: this.station.slug,
          },
        },
        label: this.station.name,
      })

      return crumbs
    },
  },

  watch: {
    $route() {
      this.fetch()
    },
  },

  created() {
    this.fetchStation()
    this.fetch()
  },

  methods: {
    async fetch() {
      this.loading = true
      const response = await this.$api.get(`stations/${this.$route.params.slug}/images`, {
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.images = response.data
      }
      this.setPages(response.meta)
    },

    async fetchStation() {
      const response = await this.$api.get(`stations/${this.$route.params.slug}`)

      if (!response.error) {
        this.station = response.data
        this.$store.commit('setBackgroundImage', this.station.backgroundImage)
      } else if (response.error.response.status === 404) {
        this.$router.replace({ name: '404' })
      }
    },
  },
}
</script>
