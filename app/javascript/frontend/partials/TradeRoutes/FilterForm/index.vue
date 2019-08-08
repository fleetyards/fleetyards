<template>
  <form @submit.prevent="filter">
    <FilterGroup
      v-model="form.cargoShip"
      fetch-path="models/cargo-options"
      :label="$t('labels.filters.cargoRoutes.cargoShip')"
      name="models"
      paginated
      searchable
    />

    <FilterGroup
      v-model="form.commodityIn"
      :label="$t('labels.filters.shops.commodity')"
      fetch-path="commodities"
      name="commodity"
      value-attr="slug"
      paginated
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.commodityTypeIn"
      :label="$t('labels.filters.shops.commodityType')"
      fetch-path="commodities/types"
      name="commodity-types"
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.commodityTypeNotIn"
      :label="$t('labels.filters.shops.excludeCommodityType')"
      fetch-path="commodities/types"
      name="exclude-commodity-types"
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.stationIn"
      :label="$t('labels.filters.shops.station')"
      fetch-path="stations"
      name="station"
      value-attr="slug"
      paginated
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.celestialObjectIn"
      :label="$t('labels.filters.stations.celestialObject')"
      fetch-path="celestial-objects"
      name="celestial-objects"
      value-attr="slug"
      paginated
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.starsystemIn"
      :label="$t('labels.filters.stations.starsystem')"
      fetch-path="starsystems"
      name="starsystems"
      value-attr="slug"
      paginated
      searchable
      multiple
    />

    <Btn
      :disabled="!isFilterSelected"
      block
      @click.native="reset"
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

  mixins: [
    Filters,
  ],

  data() {
    const query = this.$route.query.q || {}
    return {
      form: {
        cargoShip: query.cargoShip || null,
        commodityIn: query.commodityIn || [],
        commodityTypeIn: query.commodityTypeIn || [],
        commodityTypeNotIn: query.commodityTypeNotIn || [],
        stationIn: query.stationIn || [],
        celestialObjectIn: query.celestialObjectIn || [],
        starsystemIn: query.starsystemIn || [],
      },
    }
  },

  watch: {
    $route() {
      const query = this.$route.query.q || {}

      this.form = {
        cargoShip: query.cargoShip || null,
        commodityIn: query.commodityIn || [],
        commodityTypeIn: query.commodityTypeIn || [],
        commodityTypeNotIn: query.commodityTypeNotIn || [],
        stationIn: query.stationIn || [],
        celestialObjectIn: query.celestialObjectIn || [],
        starsystemIn: query.starsystemIn || [],
      }

      const storedFilters = JSON.parse(JSON.stringify(this.form))

      if (!storedFilters.cargoShip) {
        delete storedFilters.cargoShip
      }

      this.$store.commit('setFilters', { [this.$route.name]: storedFilters })
    },

    form: {
      handler() {
        this.filter()
      },
      deep: true,
    },
  },
}
</script>
