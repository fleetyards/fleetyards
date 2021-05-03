<template>
  <form @submit.prevent="filter">
    <FormInput
      id="station-name"
      v-model="form.nameCont"
      translation-key="filters.stations.name"
      :no-label="true"
      :clearable="true"
    />
    <FilterGroup
      v-model="form.celestialObjectIn"
      :label="$t('labels.filters.stations.celestialObject')"
      :fetch="fetchCelestialObjects"
      name="celestial-object"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.starsystemIn"
      :label="$t('labels.filters.stations.starsystem')"
      :fetch="fetchStarsystems"
      name="starsystem"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.stationTypeIn"
      :label="$t('labels.filters.stations.type')"
      :fetch="fetchStationTypes"
      name="station-types"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.shopsShopTypeIn"
      :label="$t('labels.filters.stations.shops')"
      :fetch="fetchShopTypes"
      name="shops"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.docksShipSizeIn"
      :label="$t('labels.filters.stations.docks')"
      :fetch="fetchShipSizes"
      name="docks"
      :multiple="true"
      :no-label="true"
    />

    <RadioList
      v-model="form.habsNotNull"
      :label="$t('labels.filters.stations.habs')"
      :reset-label="$t('labels.all')"
      :options="booleanOptions"
      name="habs"
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
import FilterGroup from 'frontend/core/components/Form/FilterGroup'
import RadioList from 'frontend/core/components/Form/RadioList'
import FormInput from 'frontend/core/components/Form/FormInput'
import Btn from 'frontend/core/components/Btn'
import { booleanOptions } from 'frontend/utils/FilterOptions'

export default {
  components: {
    FilterGroup,
    RadioList,
    FormInput,
    Btn,
  },

  mixins: [Filters],

  data() {
    const query = this.$route.query.q || {}
    return {
      loading: false,
      form: {
        searchCont: query.searchCont,
        nameCont: query.nameCont,
        habsNotNull: query.habsNotNull,
        celestialObjectIn: query.celestialObjectIn || [],
        starsystemIn: query.starsystemIn || [],
        stationTypeIn: query.stationTypeIn || [],
        shopsShopTypeIn: query.shopsShopTypeIn || [],
        docksShipSizeIn: query.docksShipSizeIn || [],
      },
    }
  },

  computed: {
    booleanOptions() {
      return booleanOptions
    },
  },

  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        searchCont: query.searchCont,
        nameCont: query.nameCont,
        habsNotNull: query.habsNotNull,
        celestialObjectIn: query.celestialObjectIn || [],
        starsystemIn: query.starsystemIn || [],
        stationTypeIn: query.stationTypeIn || [],
        shopsShopTypeIn: query.shopsShopTypeIn || [],
        docksShipSizeIn: query.docksShipSizeIn || [],
      }
    },
  },

  methods: {
    fetchCelestialObjects({ page, search, missingValue }) {
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
      return this.$api.get('celestial-objects', query)
    },
    fetchStarsystems({ page, search, missingValue }) {
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
      return this.$api.get('starsystems', query)
    },
    fetchShipSizes() {
      return this.$api.get('stations/ship-sizes')
    },
    fetchStationTypes() {
      return this.$api.get('stations/station-types')
    },
    fetchShopTypes() {
      return this.$api.get('shops/shop-types')
    },
  },
}
</script>
