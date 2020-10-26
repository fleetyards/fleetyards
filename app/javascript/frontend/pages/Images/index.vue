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
      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          :records="records"
          :loading="loading"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record, index }">
            <GalleryImage
              :src="record.smallUrl"
              :href="record.url"
              :alt="record.name"
              :title="record.caption || record.name"
              @click.native.prevent.exact="openGallery(index)"
            />
          </template>
        </FilteredGrid>
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
import FilteredGrid from 'frontend/core/components/FilteredGrid'

@Component<Images>({
  components: {
    FilteredList,
    FilteredGrid,
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
