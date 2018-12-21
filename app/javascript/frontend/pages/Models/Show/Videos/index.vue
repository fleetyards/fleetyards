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
              v-if="videos.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>
        <transition-group
          v-if="videos"
          name="fade-list"
          class="flex-row flex-center videos"
          tag="div"
          appear
        >
          <div
            v-for="video in videos"
            :key="video.id"
            class="col-xs-12 col-md-6 col-lgx-3 fade-list-item"
          >
            <div class="video embed-responsive embed-responsive-16by9">
              <iframe
                :src="video.url"
                class="embed-responsive-item"
              />
            </div>
          </div>
        </transition-group>
        <div class="row">
          <div class="col-xs-12">
            <Paginator
              v-if="videos.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>
        <Loader :loading="loading" />
      </div>
    </div>
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Pagination from 'frontend/mixins/Pagination'
import Loader from 'frontend/components/Loader'

export default {
  components: {
    Loader,
  },
  mixins: [I18n, MetaInfo, Pagination],
  data() {
    return {
      title: null,
      videos: [],
      model: null,
      loading: false,
    }
  },
  watch: {
    $route() {
      this.fetch()
    },
    model() {
      this.title = this.t('title.modelVideos', {
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
    async fetch() {
      this.loading = true
      const response = await this.$api.get(`models/${this.$route.params.slug}/videos`, {
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.videos = response.data
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
