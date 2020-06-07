<template>
  <div class="row">
    <div class="col-xs-12">
      <div class="row">
        <div class="col-xs-12 filtered-list-header">
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
          </div>
          <div class="pagination-wrapper">
            <slot name="pagination-top" />
          </div>
          <div class="page-actions page-actions-right">
            <slot name="actions" />
          </div>
        </div>
      </div>
      <div class="row">
        <transition
          name="slide"
          :appear="true"
          @before-enter="toggleFullscreen"
          @after-leave="toggleFullscreen"
        >
          <div v-if="filterVisible" class="col-xs-12 col-md-3 col-xlg-2">
            <slot v-if="!hideFilter" name="filter" />
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

<script lang="ts">
import Vue from 'vue'
import { Component, Watch, Prop } from 'vue-property-decorator'
import { Action, Mutation, Getter } from 'vuex-class'
import Btn from 'frontend/components/Btn'

@Component({
  components: {
    Btn,
  },
})
export default class FilteredList extends Vue {
  loading: boolean = true

  fullscreen: boolean = false

  @Prop({ default: false }) hideFilter!: boolean

  @Getter('filtersVisible') filtersVisible

  @Getter('mobile') mobile

  @Action('toggleFilterVisible') toggleFilterVisible

  @Mutation('setFiltersVisible') setFiltersVisible

  @Mutation('setFilters') setFilters

  get filterVisible() {
    return !!this.filtersVisible[this.$route.name] && !this.hideFilter
  }

  get filterTooltip() {
    if (this.filterVisible) {
      return this.$t('actions.hideFilter')
    }

    return this.$t('actions.showFilter')
  }

  get isFilterSelected() {
    const query = JSON.parse(JSON.stringify(this.$route.query.q || {}))
    Object.keys(query)
      .filter(key => !query[key] || query[key].length === 0)
      .forEach(key => delete query[key])
    return Object.keys(query).length > 0
  }

  get routeQuery() {
    return this.$route.query.q
  }

  @Watch('routeQuery', { deep: true })
  onRouteQueryChange() {
    this.saveFilters()
  }

  created() {
    if (this.mobile) {
      this.setFiltersVisible({
        [this.$route.name]: false,
      })
    }

    this.toggleFullscreen()
    this.saveFilters()
  }

  saveFilters() {
    if (this.isFilterSelected) {
      this.setFilters({
        [this.$route.name]: { ...this.$route.query.q },
      })

      return
    }

    this.setFilters({
      [this.$route.name]: null,
    })
  }

  toggleFullscreen() {
    this.fullscreen = !this.filterVisible
  }

  toggleFilter() {
    this.toggleFilterVisible(this.$route.name)
  }
}
</script>
