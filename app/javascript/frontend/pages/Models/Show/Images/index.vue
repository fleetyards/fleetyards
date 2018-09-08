<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <h1 class="back-button">
              {{ title }}
              <router-link
                :to="{ name: 'model', param: { slug: $route.params.slug }}"
                class="btn btn-link"
              >
                <i class="fal fa-chevron-left" />
              </router-link>
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
            class="col-xs-12 col-ms-6 col-md-3 col-lgx-2 fade-list-item"
          >
            <a
              v-lazy:background-image="image.smallUrl"
              :key="image.smallUrl"
              :data-index="index"
              :title="image.name"
              :href="image.url"
              class="image"
              @click="openGallery"
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
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Pagination from 'frontend/mixins/Pagination'
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'
import Gallery from 'frontend/components/Gallery'

export default {
  components: {
    Loader,
    Panel,
    Gallery,
  },
  mixins: [I18n, MetaInfo, Pagination],
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
      this.title = this.t('title.modelImages', {
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
    openGallery(event) {
      event.preventDefault()
      this.$refs.gallery.open(event.currentTarget.getAttribute('data-index'))
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
        without_images: true,
        without_videos: true,
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
