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

<script>
import FilteredList from '@/frontend/core/components/FilteredList/index.vue'
import FilteredGrid from '@/frontend/core/components/FilteredGrid/index.vue'
import BreadCrumbs from '@/frontend/core/components/BreadCrumbs/index.vue'
import Gallery from '@/frontend/core/components/Gallery/index.vue'
import GalleryImage from '@/frontend/core/components/Gallery/Image/index.vue'
import MetaInfo from '@/frontend/mixins/MetaInfo'
import imagesCollection from '@/frontend/api/collections/Images'

export default {
  name: 'ModelImages',

  components: {
    BreadCrumbs,
    FilteredGrid,
    FilteredList,
    Gallery,
    GalleryImage,
  },

  mixins: [MetaInfo],

  data() {
    return {
      collection: imagesCollection,
      model: null,
    }
  },

  computed: {
    crumbs() {
      if (!this.model) {
        return null
      }

      return [
        {
          label: this.$t('nav.models.index'),
          to: {
            hash: `#${this.model.slug}`,
            name: 'models',
          },
        },
        {
          label: this.model.name,
          to: { name: 'model', param: { slug: this.$route.params.slug } },
        },
      ]
    },

    metaTitle() {
      if (!this.model) {
        return null
      }

      return this.$t('title.modelImages', {
        name: this.model.name,
      })
    },

    routeParams() {
      return {
        ...this.$route.params,
        galleryType: 'models',
      }
    },
  },

  created() {
    this.fetchModel()
  },

  methods: {
    async fetchModel() {
      const response = await this.$api.get(`models/${this.$route.params.slug}`)

      if (!response.error) {
        this.model = response.data
      } else if (response.error.response.status === 404) {
        this.$router.replace({ name: '404' })
      }
    },

    openGallery(index) {
      this.$refs.gallery.open(index)
    },
  },
}
</script>
