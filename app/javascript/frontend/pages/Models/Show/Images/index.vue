<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <h1>
              <router-link
                :to="{ name: 'model', param: { slug: $route.params.slug }}"
                class="back-button"
              >
                <i class="fal fa-chevron-left" />
              </router-link>
              {{ title }}
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
            <a
              :key="image.smallUrl"
              v-lazy:background-image="image.smallUrl"
              :title="image.name"
              :href="image.url"
              class="image lazy"
              @click="openGallery(index, $event)"
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
import Gallery from 'frontend/components/Gallery'

export default {
  components: {
    Loader,
    Gallery,
  },

  mixins: [
    MetaInfo,
    Pagination,
  ],

  data() {
    return {
      title: null,
      images: [],
      model: null,
      loading: false,
    }
  },

  watch: {
    $route() {
      this.fetch()
    },

    model() {
      this.title = this.$t('title.modelImages', {
        name: this.model.name,
      })
      this.$store.commit('setBackgroundImage', this.model.backgroundImage)
    },
  },

  created() {
    this.fetchModel()
    this.fetch()
  },

  methods: {
    openGallery(index, event) {
      event.preventDefault()
      this.$refs.gallery.open(index)
    },

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
      } else if (response.error.response.status === 404) {
        this.$router.replace({ name: '404' })
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
