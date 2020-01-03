<template>
  <div class="row">
    <div class="col-xs-12">
      <div class="row">
        <div class="col-xs-12 col-md-6">
          <div class="page-actions page-actions-left">
            <Btn
              v-if="!hideFilter"
              v-tooltip="filterTooltip"
              :active="filterVisible"
              :aria-label="filterTooltip"
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
            <slot name="actions" />
          </div>
        </div>
        <div class="col-xs-12 col-md-6">
          <slot name="pagination-top" />
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
            v-if="filterVisible"
            class="col-xs-12 col-md-3 col-xlg-2"
          >
            <slot
              v-if="!hideFilter"
              name="filter"
            />
          </div>
        </transition>
        <div
          :class="{
            'col-md-9 col-xlg-10': !fullscreen,
          }"
          class="col-xs-12 col-animated"
        >
          <slot :filterVisible="filterVisible" />
        </div>
      </div>
      <div class="row">
        <div class="col-xs-12">
          <slot name="pagination-bottom" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Btn,
  },

  props: {
    hideFilter: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      fullscreen: false,
    }
  },

  computed: {
    ...mapGetters([
      'filtersVisible',
      'mobile',
    ]),

    filterVisible() {
      return !!this.filtersVisible[this.$route.name] && !this.hideFilter
    },

    filterTooltip() {
      if (this.filterVisible) {
        return this.$t('actions.hideFilter')
      }
      return this.$t('actions.showFilter')
    },

    isFilterSelected() {
      const query = JSON.parse(JSON.stringify(this.$route.query.q || {}))
      Object.keys(query)
        .filter((key) => !query[key] || query[key].length === 0)
        .forEach((key) => delete query[key])
      return Object.keys(query).length > 0
    },
  },

  created() {
    if (this.mobile) {
      this.$store.commit('setFiltersVisible', {
        [this.$route.name]: false,
      })
    }

    this.toggleFullscreen()
  },

  methods: {
    toggleFullscreen() {
      this.fullscreen = !this.filterVisible
    },

    toggleFilter() {
      this.$store.dispatch('toggleFilterVisible', this.$route.name)
    },
  },
}
</script>
