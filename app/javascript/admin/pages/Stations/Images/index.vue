<template>
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
    <template #default="{ records, loading }">
      <ImageUploader
        :loading="loading"
        :images="records"
        :gallery-id="galleryId"
        gallery-type="Model"
        @image-deleted="fetch"
        @image-uploaded="fetch"
      />
    </template>
  </FilteredList>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import ImageUploader from 'admin/components/ImageUploader'
import FilteredList from 'frontend/core/components/FilteredList'
import imagesCollection, {
  AdminImagesCollection,
} from 'admin/api/collections/Images'

@Component<AdminStationImages>({
  components: {
    ImageUploader,
    FilteredList,
  },
})
export default class AdminStationImages extends Vue {
  collection: AdminImagesCollection = imagesCollection

  get galleryId() {
    return this.$route.params.uuid
  }

  get routeParams() {
    return {
      galleryType: 'stations',
      galleryId: this.galleryId,
    }
  }

  get filters() {
    return {
      ...this.routeParams,
      page: this.$route.query.page,
    }
  }

  async fetch() {
    await this.collection.findAllForGallery(this.filters)
  }
}
</script>
