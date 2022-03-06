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
import MetaInfo from '@/frontend/mixins/MetaInfo'
import FilteredList from '@/frontend/core/components/FilteredList/index.vue'
import FilteredGrid from '@/frontend/core/components/FilteredGrid/index.vue'
import BreadCrumbs from '@/frontend/core/components/BreadCrumbs/index.vue'
import Gallery from '@/frontend/core/components/Gallery/index.vue'
import GalleryImage from '@/frontend/core/components/Gallery/Image/index.vue'
import imagesCollection from '@/frontend/api/collections/Images'

export default {
  name: 'StationImages',
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
      station: null,
    }
  },

  computed: {
    crumbs() {
      if (!this.station) {
        return null
      }

      const crumbs = [
        {
          label: this.$t('nav.starsystems'),
          to: {
            hash: `#${this.station.celestialObject.starsystem.slug}`,
            name: 'starsystems',
          },
        },
        {
          label: this.station.celestialObject.starsystem.name,
          to: {
            hash: `#${this.station.celestialObject.slug}`,
            name: 'starsystem',
            params: {
              slug: this.station.celestialObject.starsystem.slug,
            },
          },
        },
      ]

      if (this.station.celestialObject.parent) {
        crumbs.push({
          label: this.station.celestialObject.parent.name,
          to: {
            name: 'celestial-object',
            params: {
              slug: this.station.celestialObject.parent.slug,
              starsystem: this.station.celestialObject.starsystem.slug,
            },
          },
        })
      }

      crumbs.push({
        label: this.station.celestialObject.name,
        to: {
          hash: `#${this.station.slug}`,
          name: 'celestial-object',
          params: {
            slug: this.station.celestialObject.slug,
            starsystem: this.station.celestialObject.starsystem.slug,
          },
        },
      })

      crumbs.push({
        label: this.station.name,
        to: {
          name: 'station',
          params: {
            slug: this.station.slug,
          },
        },
      })

      return crumbs
    },

    metaTitle() {
      if (!this.station) {
        return null
      }

      return this.$t('title.stationImages', {
        celestialObject: this.station.celestialObject.name,
        station: this.station.name,
      })
    },

    routeParams() {
      return {
        ...this.$route.params,
        galleryType: 'stations',
      }
    },
  },

  created() {
    this.fetchStation()
  },

  methods: {
    async fetchStation() {
      const response = await this.$api.get(
        `stations/${this.$route.params.slug}`
      )

      if (!response.error) {
        this.station = response.data
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
