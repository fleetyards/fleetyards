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
      model: null,
      loading: false,
    }
  },

  computed: {
    metaTitle() {
      if (!this.model) {
        return null
      }

      return this.$t('title.modelImages', {
        name: this.model.name,
      })
    },

    crumbs() {
      if (!this.model) {
        return null
      }

      return [{
        to: {
          name: 'models',
          hash: `#${this.model.slug}`,
        },
        label: this.$t('nav.models'),
      }, {
        to: { name: 'model', param: { slug: this.$route.params.slug } },
        label: this.model.name,
      }]
    },
  },

  watch: {
    $route() {
      this.fetch()
    },
  },

  created() {
    this.fetchModel()
    this.fetch()
  },

  methods: {
    async fetch() {
      this.loading = true
      const response = await this.$api.get(`models/${this.$route.params.slug}/images`, {
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.images = response.data
      }
      this.setPages(response.meta)
    },

    async fetchModel() {
      const response = await this.$api.get(`models/${this.$route.params.slug}`, {
        withoutImages: true,
        withoutVideos: true,
      })

      if (!response.error) {
        this.model = response.data
        this.$store.commit('setBackgroundImage', this.model.backgroundImage)
      } else if (response.error.response.status === 404) {
        this.$router.replace({ name: '404' })
      }
    },
  },
}
</script>
