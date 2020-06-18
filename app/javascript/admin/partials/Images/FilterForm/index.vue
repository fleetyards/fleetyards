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

<script>
import Filters from 'frontend/mixins/Filters'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    FilterGroup,
    Btn,
  },

  mixins: [Filters],

  data() {
    const query = this.$route.query.q || {}

    return {
      loading: false,
      modelIdEq: null,
      stationIdEq: null,
      form: {
        galleryIdEq: query.galleryIdEq,
        galleryTypeEq: query.galleryTypeEq,
      },
    }
  },

  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        galleryIdEq: query.galleryIdEq,
        galleryTypeEq: query.galleryTypeEq,
      }
    },

    modelIdEq(value) {
      if (value) {
        this.stationIdEq = null
        this.form.galleryIdEq = value
        this.form.galleryTypeEq = 'Model'
      } else if (!this.stationIdEq) {
        this.form.galleryIdEq = null
        this.form.galleryTypeEq = null
      }
    },

    stationIdEq(value) {
      if (value) {
        this.modelIdEq = null
        this.form.galleryIdEq = value
        this.form.galleryTypeEq = 'Station'
      } else if (!this.modelIdEq) {
        this.form.galleryIdEq = null
        this.form.galleryTypeEq = null
      }
    },

    form: {
      handler() {
        if (!this.form.galleryIdEq && !this.form.galleryTypeEq) {
          this.modelIdEq = null
          this.stationIdEq = null
        }
      },
      deep: true,
    },
  },

  methods: {
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
    },

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
    },
  },
}
</script>
