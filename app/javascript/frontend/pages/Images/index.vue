<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <h1 class="sr-only">
              {{ $t('headlines.images') }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-12">
            <Paginator
              v-if="collection.records.length"
              :page="collection.currentPage"
              :total="collection.totalPages"
              :center="true"
            />
          </div>
        </div>
        <transition-group
          v-if="collection.records.length"
          name="fade-list"
          class="flex-row flex-center images"
          tag="div"
          appear
        >
          <div
            v-for="(image, index) in collection.records"
            :key="image.id"
            class="col-12 col-ms-6 col-md-6 col-lg-4 col-xxlg-2-4 fade-list-item"
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
          <div class="col-12">
            <Paginator
              v-if="collection.records.length"
              :page="collection.currentPage"
              :total="collection.totalPages"
              :center="true"
            />
          </div>
        </div>
        <Loader :loading="loading" />
      </div>
    </div>

    <Gallery ref="gallery" :items="collection.records" />
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Pagination from 'frontend/mixins/Pagination'
import Loader from 'frontend/components/Loader'
import GalleryHelpers from 'frontend/mixins/GalleryHelpers'
import imagesCollection from 'frontend/collections/Images'

@Component<Images>({
  components: {
    Loader,
  },
  mixins: [MetaInfo, Pagination, GalleryHelpers],
})
export default class Images extends Vue {
  collection: ImagesCollection = imagesCollection

  loading: boolean = false

  @Watch('$route')
  onRouteChange() {
    this.fetch()
  }

  created() {
    this.fetch()
  }

  async fetch() {
    this.loading = true
    this.collection.findAll({ page: this.$route.params.page })
    this.loading = false
  }
}
</script>
