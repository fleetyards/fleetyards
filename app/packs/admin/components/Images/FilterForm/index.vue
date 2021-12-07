<template>
  <form @submit.prevent="filter">
    <FilterGroup
      v-model="modelIdEq"
      :label="$t('labels.filters.images.model')"
      :fetch="fetchModels"
      name="model"
      :searchable="true"
      :paginated="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="stationIdEq"
      :label="$t('labels.filters.images.station')"
      :fetch="fetchStations"
      name="station"
      :searchable="true"
      :paginated="true"
      :no-label="true"
    />

    <Btn
      :disabled="!isFilterSelected"
      :block="true"
      @click.native="resetFilter"
    >
      <i class="fal fa-times" />
      {{ $t('actions.resetFilter') }}
    </Btn>
  </form>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import Filters from 'frontend/mixins/Filters'
import FilterGroup from 'frontend/core/components/Form/FilterGroup'
import Btn from 'frontend/core/components/Btn'

@Component<FilterForm>({
  components: {
    FilterGroup,
    Btn,
  },
  mixins: [Filters],
})
export default class FilterForm extends Vue {
  loading: boolean = false

  modelIdEq: string | null = null

  stationIdEq: string | null = null

  form: GalleryFilters = {
    galleryIdEq: this.routeQuery.galleryIdEq,
    galleryTypeEq: this.routeQuery.galleryTypeEq,
  }

  get routeQuery() {
    return this.$route.query.q || {}
  }

  @Watch('$route')
  onRouteChange() {
    const query = this.$route.query.q || {}
    this.form = {
      galleryIdEq: query.galleryIdEq,
      galleryTypeEq: query.galleryTypeEq,
    }
  }

  @Watch('modelIdEq')
  onModelIdFilterChange(value) {
    if (value) {
      this.stationIdEq = null
      this.form.galleryIdEq = value
      this.form.galleryTypeEq = 'Model'
    } else if (!this.stationIdEq) {
      this.form.galleryIdEq = null
      this.form.galleryTypeEq = null
    }
  }

  @Watch('stationIdEq')
  onStationIdFitlerChange(value) {
    if (value) {
      this.modelIdEq = null
      this.form.galleryIdEq = value
      this.form.galleryTypeEq = 'Station'
    } else if (!this.modelIdEq) {
      this.form.galleryIdEq = null
      this.form.galleryTypeEq = null
    }
  }

  @Watch('form', { deep: true })
  onFormChange() {
    if (!this.form.galleryIdEq && !this.form.galleryTypeEq) {
      this.modelIdEq = null
      this.stationIdEq = null
    }
  }

  fetchModels({ page, search, missingValue }) {
    const query = {
      q: {},
    }
    if (search) {
      query.q.nameCont = search
    } else if (missingValue) {
      query.q.nameIn = missingValue
    } else if (page) {
      query.page = page
    }
    return this.$api.get('models/options', query)
  }

  fetchStations({ page, search, missingValue }) {
    const query = {
      q: {},
    }
    if (search) {
      query.q.nameCont = search
    } else if (missingValue) {
      query.q.nameIn = missingValue
    } else if (page) {
      query.page = page
    }
    return this.$api.get('stations/options', query)
  }
}
</script>
