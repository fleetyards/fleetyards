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

<script>
import ImageUploader from '@/admin/components/ImageUploader/index.vue'
import FilterForm from '@/admin/components/Images/FilterForm/index.vue'
import FilteredList from '@/frontend/core/components/FilteredList/index.vue'
import imagesCollection from '@/admin/api/collections/Images'

export default {
  name: 'AdminImages',

  components: {
    FilteredList,
    FilterForm,
    ImageUploader,
  },

  data() {
    return {
      collection: imagesCollection,
    }
  },

  computed: {
    galleryId() {
      return this.query.galleryIdEq
    },

    galleryType() {
      return this.query.galleryTypeEq
    },

    query() {
      return this.$route.query.q || {}
    },

    toggleFiltersTooltip() {
      if (this.filterVisible) {
        return this.$t('actions.hideFilter')
      }
      return this.$t('actions.showFilter')
    },
  },

  methods: {
    async fetch() {
      await this.collection.refresh()
    },
  },
}
</script>
