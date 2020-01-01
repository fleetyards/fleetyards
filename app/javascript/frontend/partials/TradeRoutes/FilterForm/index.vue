<template>
  <form @submit.prevent="filter">
    <template v-if="mobile">
      <FilterGroup
        v-model="form.originIn"
        :label="$t('labels.filters.tradeRoutes.origin')"
        fetch-path="stations?origin"
        name="origin"
        value-attr="slug"
        paginated
        searchable
        multiple
      />

      <FilterGroup
        v-model="form.destinationIn"
        :label="$t('labels.filters.tradeRoutes.destination')"
        fetch-path="stations?destination"
        name="destination"
        value-attr="slug"
        paginated
        searchable
        multiple
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

      <hr>
    </template>

    <FilterGroup
      v-model="form.cargoShip"
      fetch-path="models/cargo-options"
      :label="$t('labels.filters.tradeRoutes.cargoShip')"
      name="models"
      paginated
      searchable
    />

    <FilterGroup
      v-model="form.commodityTypeNotIn"
      :label="$t('labels.filters.tradeRoutes.excludeCommodityType')"
      fetch-path="commodities/types"
      name="exclude-commodity-types"
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
      @click.native="resetFilter"
    >
      <i class="fal fa-times" />
      {{ $t('actions.resetFilter') }}
    </Btn>
  </form>
</template>

<script>
import { mapGetters } from 'vuex'

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
        commodityTypeNotIn: query.commodityTypeNotIn || [],
        originIn: query.originIn || [],
        destinationIn: query.destinationIn || [],
        celestialObjectIn: query.celestialObjectIn || [],
        starsystemIn: query.starsystemIn || [],
      },
    }
  },

  computed: {
    ...mapGetters([
      'mobile',
    ]),
  },

  watch: {
    $route() {
      const query = this.$route.query.q || {}

      this.form = {
        cargoShip: query.cargoShip || null,
        commodityIn: query.commodityIn || [],
        commodityTypeNotIn: query.commodityTypeNotIn || [],
        originIn: query.originIn || [],
        destinationIn: query.destinationIn || [],
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
