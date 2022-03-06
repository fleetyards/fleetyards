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

<script>
import ImageUploader from '@/admin/components/ImageUploader/index.vue'
import FilteredList from '@/frontend/core/components/FilteredList/index.vue'
import imagesCollection from '@/admin/api/collections/Images'

export default {
  name: 'AdminModelImages',
  components: {
    FilteredList,
    ImageUploader,
  },

  data() {
    return {
      collection: imagesCollection,
    }
  },

  computed: {
    filters() {
      return {
        ...this.routeParams,
        page: this.$route.query.page,
      }
    },

    galleryId() {
      return this.$route.params.uuid
    },

    grouteParams() {
      return {
        galleryId: this.galleryId,
        galleryType: 'models',
      }
    },
  },

  methods: {
    async fetch() {
      await this.collection.findAllForGallery(this.filters)
    },
  },
}
</script>
