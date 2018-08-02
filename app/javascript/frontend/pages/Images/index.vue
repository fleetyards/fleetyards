<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12 col-md-8">
            <h1 class="sr-only">{{ t('headlines.images') }}</h1>
          </div>
          <div class="col-xs-12 col-md-4 text-right"/>
        </div>
        <transition-group
          v-if="images"
          name="fade-list"
          class="flex-row flex-center"
          tag="div"
          appear
        >
          <div
            v-for="(image, index) in images"
            :key="image.id"
            class="col-xs-6 col-sm-4 col-md-3 fade-list-item"
          >
            <a
              :data-index="index"
              :title="image.name"
              class="thumbnail"
              @click="openGallery"
            >
              <img
                v-lazy="image.smallUrl"
                class="img-responsive"
                alt="Image"
              >
            </a>
          </div>
        </transition-group>
        <InfiniteLoading
          v-if="images && images.length >= limit"
          ref="infiniteLoading"
          :distance="500"
          @infinite="fetchMore"
        >
          <span slot="no-more" />
          <span slot="spinner">
            <Loader
              v-if="loading"
              static
            />
          </span>
        </InfiniteLoading>
        <Loader v-if="loading" />
      </div>
    </div>
    <Gallery
      ref="gallery"
      :images="images"
    />
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Gallery from 'frontend/components/Gallery'
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'
import InfiniteLoading from 'vue-infinite-loading'

export default {
  components: {
    Gallery,
    Loader,
    InfiniteLoading,
    Panel,
  },
  mixins: [I18n, MetaInfo],
  data() {
    return {
      limit: 30,
      offset: 0,
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
    openGallery(event) {
      this.$refs.gallery.open(event.currentTarget.getAttribute('data-index'))
    },
    fetch() {
      this.loading = true
      this.$api.get('images', {
        limit: this.limit,
      }, (args) => {
        this.loading = false
        if (!args.error) {
          this.images = args.data
        }
      })
    },
    fetchMore($state) {
      this.loading = true
      this.offset += this.limit
      this.$api.get('images', {
        limit: this.limit,
        offset: this.offset,
      }, (args) => {
        this.loading = false
        $state.loaded()
        if (!args.error) {
          if (args.data.length === 0 || args.data.length < this.limit) {
            $state.complete()
          }

          args.data.forEach((image) => {
            this.images.push(image)
          })
        }
      })
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.images')
    })
  },
}
</script>
