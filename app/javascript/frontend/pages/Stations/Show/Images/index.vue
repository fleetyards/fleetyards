<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <h1>
              <router-link
                :to="{ name: 'station', param: { slug: $route.params.slug }}"
                class="back-button"
              >
                <i class="fal fa-chevron-left" />
              </router-link>
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

export default {
  components: {
    Loader,
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
