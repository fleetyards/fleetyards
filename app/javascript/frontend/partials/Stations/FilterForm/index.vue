<template>
  <form @submit.prevent="filter">
    <div class="form-group">
      <label :for="idFor('stations-name')">
        {{ t('labels.filters.stations.name') }}
      </label>
      <input
        :id="idFor('stations-name')"
        v-model="form.nameCont"
        :placeholder="t('placeholders.filters.stations.name')"
        type="text"
        class="form-control"
      >
      <a
        v-if="form.nameCont"
        class="btn btn-clear"
        @click="clearName"
        v-html="'&times;'"
      />
    </div>
    <FilterGroup
      v-model="form.celestialObjectIn"
      :label="t('labels.filters.stations.celestialObject')"
      :fetch="fetchCelestialObjects"
      name="celestial-object"
      value-attr="slug"
      paginated
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.starsystemIn"
      :label="t('labels.filters.stations.starsystem')"
      :fetch="fetchStarsystems"
      name="starsystem"
      value-attr="slug"
      paginated
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.stationTypeIn"
      :label="t('labels.filters.stations.type')"
      :fetch="fetchStationTypes"
      name="station-types"
      multiple
    />
    <FilterGroup
      v-model="form.shopsShopTypeIn"
      :label="t('labels.filters.stations.shops')"
      :fetch="fetchShopTypes"
      name="shops"
      multiple
    />
    <FilterGroup
      v-model="form.docksShipSizeIn"
      :label="t('labels.filters.stations.docks')"
      :fetch="fetchShipSizes"
      name="docks"
      multiple
    />
    <RadioList
      :label="t('labels.filters.stations.habs')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      v-model="form.habsNotNull"
      name="habs"
    />
    <!-- <br>
    Filter by Status -->
    <Btn
      :disabled="!isFilterSelected"
      block
      @click.native="reset"
    >
      <i class="fal fa-times" />
      {{ t('actions.resetFilter') }}
    </Btn>
  </form>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Filters from 'frontend/mixins/Filters'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import RadioList from 'frontend/components/Form/RadioList'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    FilterGroup,
    RadioList,
    Btn,
  },
  mixins: [I18n, Filters],
  data() {
    const query = this.$route.query.q || {}
    return {
      loading: false,
      form: {
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
  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        nameCont: query.nameCont,
        habsNotNull: query.habsNotNull,
        celestialObjectIn: query.celestialObjectIn || [],
        starsystemIn: query.starsystemIn || [],
        stationTypeIn: query.stationTypeIn || [],
        shopsShopTypeIn: query.shopsShopTypeIn || [],
        docksShipSizeIn: query.docksShipSizeIn || [],
      }
      this.$store.commit('setFilters', { [this.$route.name]: this.form })
    },
    form: {
      handler() {
        this.filter()
      },
      deep: true,
    },
  },
  methods: {
    clearName() {
      this.form.nameCont = null
    },
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
