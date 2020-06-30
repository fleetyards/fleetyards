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
      </div>
    </div>

    <FilteredList
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :hash="$route.hash"
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
import Gallery from 'frontend/core/components/Gallery'
import GalleryImage from 'frontend/core/components/Gallery/Image'
import imagesCollection from 'frontend/api/collections/Images'
import FilteredList from 'frontend/core/components/FilteredList'

@Component<Images>({
  components: {
    FilteredList,
    Gallery,
    GalleryImage,
  },
  mixins: [MetaInfo],
})
export default class Images extends Vue {
  collection: ImagesCollection = imagesCollection

  openGallery(index) {
    this.$refs.gallery.open(index)
  }
}
</script>
