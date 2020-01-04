<template>
  <div class="row">
    <div class="col-xs-12">
      <div class="row">
        <div class="col-xs-12 col-md-6">
          <div class="page-actions page-actions-left">
            <Btn
              v-tooltip="toggleFiltersTooltip"
              :active="filterVisible"
              :aria-label="toggleFiltersTooltip"
              size="small"
              @click.native="toggleFilter"
            >
              <span v-show="isFilterSelected">
                <i class="fas fa-filter" />
              </span>
              <span v-show="!isFilterSelected">
                <i class="far fa-filter" />
              </span>
            </Btn>
          </div>
        </div>
        <div class="col-xs-12 col-md-6">
          <Paginator
            v-if="images.length"
            :page="currentPage"
            :total="totalPages"
            right
          />
        </div>
      </div>
      <div class="row">
        <transition
          name="slide"
          appear
          @before-enter="toggleFullscreen"
          @after-leave="toggleFullscreen"
        >
          <div
            v-show="filterVisible"
            class="col-xs-12 col-md-3 col-xlg-2"
          >
            <FilterForm />
          </div>
        </transition>
        <div
          :class="{
            'col-md-9 col-xlg-10': !fullscreen,
          }"
          class="col-xs-12 col-animated"
        >
          <ImageUploader
            :loading="loading"
            :images="images"
            :gallery-id="galleryId"
            :gallery-type="galleryType"
            @imageDeleted="fetch"
            @imageUploaded="fetch"
          />
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <Paginator
          v-if="images.length"
          :page="currentPage"
          :total="totalPages"
          right
        />
      </div>
    </div>
  </div>
</template>

<script>
import ImageUploader from 'admin/components/ImageUploader'
import FilterForm from 'admin/partials/Images/FilterForm'
import Pagination from 'frontend/mixins/Pagination'
import Filters from 'frontend/mixins/Filters'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    ImageUploader,
    FilterForm,
    Btn,
  },
  mixins: [Filters, Pagination],
  data() {
    return {
      loading: true,
      images: [],
      filterVisible: true,
      fullscreen: false,
    }
  },
  computed: {
    toggleFiltersTooltip() {
      if (this.filterVisible) {
        return this.$t('actions.hideFilter')
      }
      return this.$t('actions.showFilter')
    },
    query() {
      return this.$route.query.q || {}
    },
    galleryId() {
      return this.query.galleryIdEq
    },
    galleryType() {
      return this.query.galleryTypeEq
    },
  },
  watch: {
    $route() {
      this.fetch()
    },
  },
  mounted() {
    this.fetch()
  },
  methods: {
    toggleFullscreen() {
      this.fullscreen = !this.filterVisible
    },
    toggleFilter() {
      this.filterVisible = !this.filterVisible
    },
    async fetch() {
      this.loading = true

      const response = await this.$api.get('images', {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })

      this.loading = false
      if (!response.error) {
        this.images = response.data
      }
      this.setPages(response.meta)
    },
  },
}
</script>
