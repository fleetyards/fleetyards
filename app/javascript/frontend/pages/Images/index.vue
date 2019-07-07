<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <h1 class="sr-only">
              {{ $t('headlines.images') }}
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
    MetaInfo,
    Pagination,
    GalleryHelpers,
  ],

  data() {
    return {
      images: [],
      loading: false,
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
      const response = await this.$api.get('images', {
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.images = response.data
      }
      this.setPages(response.meta)
    },
  },

  metaInfo() {
    return this.getMetaInfo({
      title: this.$t('title.images'),
    })
  },
}
</script>
