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
        <div class="row">
          <div class="col-xs-12">
            <Paginator
              v-if="images.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>
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
import Pagination from 'frontend/mixins/Pagination'
import Gallery from 'frontend/components/Gallery'
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'

export default {
  components: {
    Gallery,
    Loader,
    Panel,
  },
  mixins: [I18n, MetaInfo, Pagination],
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
    openGallery(event) {
      this.$refs.gallery.open(event.currentTarget.getAttribute('data-index'))
    },
    fetch() {
      this.loading = true
      this.$api.get('images', {
        page: this.$route.query.page,
      }, (args) => {
        this.loading = false
        if (!args.error) {
          this.images = args.data
        }
        this.setPages(args.meta)
      })
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.images'),
    })
  },
}
</script>
