<template>
  <FilteredList
    :collection="collection"
    :name="$route.name"
    :route-query="$route.query"
    :hash="$route.hash"
    :paginated="true"
    class="images"
  >
    <FilterForm slot="filter" />

    <template #default="{ records, loading }">
      <ImageUploader
        :loading="loading"
        :images="records"
        :gallery-id="galleryId"
        :gallery-type="galleryType"
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
import FilterForm from 'admin/components/Images/FilterForm'
import FilteredList from 'frontend/core/components/FilteredList'
import imagesCollection, {
  AdminImagesCollection,
} from 'admin/api/collections/Images'

@Component<AdminImages>({
  components: {
    ImageUploader,
    FilterForm,
    FilteredList,
  },
})
export default class AdminImages extends Vue {
  collection: AdminImagesCollection = imagesCollection

  get toggleFiltersTooltip() {
    if (this.filterVisible) {
      return this.$t('actions.hideFilter')
    }
    return this.$t('actions.showFilter')
  }

  get query() {
    return this.$route.query.q || {}
  }

  get galleryId() {
    return this.query.galleryIdEq
  }

  get galleryType() {
    return this.query.galleryTypeEq
  }

  async fetch() {
    await this.collection.refresh()
  }
}
</script>
