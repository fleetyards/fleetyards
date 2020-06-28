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
      </div>
    </div>
    <FilteredList
      :collection="collection"
      collection-method="findAllForGallery"
      :name="$route.name"
      :route-query="$route.query"
      :hash="$route.hash"
      :params="routeParams"
      :paginated="true"
      class="images"
    >
      <template v-slot:record="{ record, index }">
        <GalleryImage
          :src="record.smallUrl"
          :href="record.url"
          :alt="record.name"
          @click.native.prevent.exact="openGallery(index)"
        />
      </template>
    </FilteredList>

    <Gallery ref="gallery" :items="collection.records" />
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FilteredList from 'frontend/components/FilteredList'
import BreadCrumbs from 'frontend/components/BreadCrumbs'
import Gallery from 'frontend/components/Gallery'
import GalleryImage from 'frontend/components/GalleryImage'
import imagesCollection from 'frontend/collections/Images'

@Component<ModelImages>({
  components: {
    FilteredList,
    BreadCrumbs,
    Gallery,
    GalleryImage,
  },
  mixins: [MetaInfo],
})
export default class ModelImages extends Vue {
  collection: ImagesCollection = imagesCollection

  model: Model | null = null

  get metaTitle() {
    if (!this.model) {
      return null
    }

    return this.$t('title.modelImages', {
      name: this.model.name,
    })
  }

  get routeParams() {
    return {
      ...this.$route.params,
      galleryType: 'models',
    }
  }

  get crumbs() {
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
  }

  created() {
    this.fetchModel()
  }

  openGallery(index) {
    this.$refs.gallery.open(index)
  }

  async fetchModel() {
    const response = await this.$api.get(`models/${this.$route.params.slug}`)

    if (!response.error) {
      this.model = response.data
    } else if (response.error.response.status === 404) {
      this.$router.replace({ name: '404' })
    }
  }
}
</script>
