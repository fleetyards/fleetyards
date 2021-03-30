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

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FilteredList from 'frontend/core/components/FilteredList'
import FilteredGrid from 'frontend/core/components/FilteredGrid'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import Gallery from 'frontend/core/components/Gallery'
import GalleryImage from 'frontend/core/components/Gallery/Image'
import imagesCollection from 'frontend/api/collections/Images'

@Component<ModelImages>({
  components: {
    FilteredList,
    FilteredGrid,
    BreadCrumbs,
    Gallery,
    GalleryImage,
  },
  mixins: [MetaInfo],
})
export default class ModelImages extends Vue {
  collection: ImagesCollection = imagesCollection

  station: Station | null = null

  get metaTitle() {
    if (!this.station) {
      return null
    }

    return this.$t('title.stationImages', {
      station: this.station.name,
      celestialObject: this.station.celestialObject.name,
    })
  }

  get routeParams() {
    return {
      ...this.$route.params,
      galleryType: 'stations',
    }
  }

  get crumbs() {
    if (!this.station) {
      return null
    }

    const crumbs = [
      {
        to: {
          name: 'starsystems',
          hash: `#${this.station.celestialObject.starsystem.slug}`,
        },
        label: this.$t('nav.starsystems'),
      },
      {
        to: {
          name: 'starsystem',
          params: {
            slug: this.station.celestialObject.starsystem.slug,
          },
          hash: `#${this.station.celestialObject.slug}`,
        },
        label: this.station.celestialObject.starsystem.name,
      },
    ]

    if (this.station.celestialObject.parent) {
      crumbs.push({
        to: {
          name: 'celestial-object',
          params: {
            starsystem: this.station.celestialObject.starsystem.slug,
            slug: this.station.celestialObject.parent.slug,
          },
        },
        label: this.station.celestialObject.parent.name,
      })
    }

    crumbs.push({
      to: {
        name: 'celestial-object',
        params: {
          starsystem: this.station.celestialObject.starsystem.slug,
          slug: this.station.celestialObject.slug,
        },
        hash: `#${this.station.slug}`,
      },
      label: this.station.celestialObject.name,
    })

    crumbs.push({
      to: {
        name: 'station',
        params: {
          slug: this.station.slug,
        },
      },
      label: this.station.name,
    })

    return crumbs
  }

  created() {
    this.fetchStation()
  }

  openGallery(index) {
    this.$refs.gallery.open(index)
  }

  async fetchStation() {
    const response = await this.$api.get(`stations/${this.$route.params.slug}`)

    if (!response.error) {
      this.station = response.data
    } else if (response.error.response.status === 404) {
      this.$router.replace({ name: '404' })
    }
  }
}
</script>
