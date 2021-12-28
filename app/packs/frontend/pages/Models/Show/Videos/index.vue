<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <BreadCrumbs :crumbs="crumbs" />
            <h1>
              {{ metaTitle }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-12">
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
          class="row flex-center videos"
          tag="div"
          appear
        >
          <div
            v-for="video in videos"
            :key="video.id"
            class="col-12 col-lg-6 col-lgx-3 fade-list-item"
          >
            <div class="video embed-responsive embed-responsive-16by9">
              <template v-if="video.type === 'youtube' && youtubeEnabled">
                <iframe :src="video.url" class="embed-responsive-item" />
              </template>
              <div
                v-else-if="video.type === 'youtube'"
                class="youtube-placeholder"
              >
                <i class="fab fa-youtube" />
                <div class="youtube-placeholder-buttons">
                  <Btn :inline="true" @click.native="enableYoutube">
                    Allow video embeds
                  </Btn>
                  <Btn :inline="true" @click.native="copyVideoUrl(video)">
                    Copy Youtube URL
                  </Btn>
                </div>
              </div>
            </div>
          </div>
        </transition-group>
        <div class="row">
          <div class="col-12">
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
import { mapGetters } from 'vuex'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Pagination from 'frontend/mixins/Pagination'
import Loader from 'frontend/core/components/Loader'
import Btn from 'frontend/core/components/Btn'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import copyText from 'frontend/utils/CopyText'
import { displaySuccess, displayAlert } from 'frontend/lib/Noty'

export default {
  components: {
    Loader,
    Btn,
    BreadCrumbs,
  },

  mixins: [MetaInfo, Pagination],

  data() {
    return {
      videos: [],
      model: null,
      loading: false,
    }
  },

  computed: {
    ...mapGetters('cookies', ['cookies']),

    metaTitle() {
      if (!this.model) {
        return null
      }

      return this.$t('title.modelVideos', {
        name: this.model.name,
      })
    },

    crumbs() {
      if (!this.model) {
        return null
      }

      return [
        {
          to: {
            name: 'models',
            hash: `#${this.model.slug}`,
          },
          label: this.$t('nav.models.index'),
        },
        {
          to: { name: 'model', param: { slug: this.$route.params.slug } },
          label: this.model.name,
        },
      ]
    },

    youtubeEnabled() {
      return this.cookies.youtube
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
    copyVideoUrl(video) {
      copyText(`https://www.youtube.com/watch?v=${video.videoId}`).then(
        () => {
          displaySuccess({
            text: this.$t('messages.copyVideoUrl.success'),
          })
        },
        () => {
          displayAlert({
            text: this.$t('messages.copyVideoUrl.failure'),
          })
        }
      )
    },

    enableYoutube() {
      this.$comlink.$emit('open-privacy-settings')
    },

    async fetch() {
      this.loading = true

      const response = await this.$api.get(
        `models/${this.$route.params.slug}/videos`,
        {
          page: this.$route.query.page,
        }
      )

      this.loading = false

      if (!response.error) {
        this.videos = response.data
      }

      this.setPages(response.meta)
    },

    async fetchModel() {
      const response = await this.$api.get(`models/${this.$route.params.slug}`)

      if (!response.error) {
        this.model = response.data
      } else if (response.error.response.status === 404) {
        this.$router.replace({ name: '404' })
      }
    },
  },
}
</script>
