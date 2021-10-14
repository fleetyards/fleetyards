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

@Component<AdminModelImages>({
  components: {
    ImageUploader,
    FilteredList,
  },
})
export default class AdminModelImages extends Vue {
  get galleryId() {
    return this.$route.params.uuid
  }

  get routeParams() {
    return {
      galleryType: 'models',
      galleryId: this.galleryId,
    }
  }

  get filters() {
    return {
      ...this.routeParams,
      page: this.$route.query.page,
    }
  }

  collection: AdminImagesCollection = imagesCollection

  async fetch() {
    await this.collection.findAllForGallery(this.filters)
  }
}
</script>
