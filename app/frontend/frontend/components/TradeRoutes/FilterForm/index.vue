<template>
  <form @submit.prevent="filter">
    <template v-if="mobile">
      <FilterGroup
        v-model="form.originStationIn"
        :label="$t('labels.filters.tradeRoutes.origin')"
        fetch-path="stations?origin"
        name="origin"
        value-attr="slug"
        :paginated="true"
        :searchable="true"
        :multiple="true"
        :no-label="true"
      />

      <FilterGroup
        v-model="form.destinationStationIn"
        :label="$t('labels.filters.tradeRoutes.destination')"
        fetch-path="stations?destination"
        name="destination"
        value-attr="slug"
        :paginated="true"
        :searchable="true"
        :multiple="true"
        :no-label="true"
      />

      <FilterGroup
        v-model="form.commodityIn"
        :label="$t('labels.filters.shops.commodity')"
        fetch-path="commodities"
        name="commodity"
        value-attr="slug"
        :paginated="true"
        :searchable="true"
        :multiple="true"
        :no-label="true"
      />

      <hr />
    </template>

    <FilterGroup
      v-model="form.cargoShip"
      fetch-path="models/cargo-options"
      :label="$t('labels.filters.tradeRoutes.cargoShip')"
      name="models"
      :paginated="true"
      :searchable="true"
    />

    <FilterGroup
      v-model="form.commodityTypeNotIn"
      :label="$t('labels.filters.tradeRoutes.excludeCommodityType')"
      fetch-path="commodities/types"
      name="exclude-commodity-types"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      v-model="form.originCelestialObjectIn"
      :label="$t('labels.filters.tradeRoutes.originCelestialObject')"
      :collection="celestialObjectCollection"
      name="origin-celestial-objects"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      v-model="form.destinationCelestialObjectIn"
      :label="$t('labels.filters.tradeRoutes.destinationCelestialObject')"
      :collection="celestialObjectCollection"
      name="destination-celestial-objects"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      v-model="form.originStarsystemIn"
      :collection="starsystemCollection"
      :label="$t('labels.filters.tradeRoutes.originStarsystem')"
      name="origin-starsystems"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      v-model="form.destinationStarsystemIn"
      :collection="starsystemCollection"
      :label="$t('labels.filters.tradeRoutes.destinationStarsystem')"
      name="destination-starsystems"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
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
import { mapGetters } from 'vuex'
import Filters from '@/frontend/mixins/Filters'
import FilterGroup from '@/frontend/core/components/Form/FilterGroup/index.vue'
import CollectionFilterGroup from '@/frontend/core/components/Form/CollectionFilterGroup/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import celestialObjectCollection from '@/frontend/api/collections/CelestialObjects'
import starsystemCollection from '@/frontend/api/collections/Starsystems'

export default {
  name: 'TradeRoutesFilterForm',

  components: {
    Btn,
    CollectionFilterGroup,
    FilterGroup,
  },

  mixins: [Filters],

  data() {
    return {
      celestialObjectCollection: celestialObjectCollection,
      form: {},
      starsystemCollection: starsystemCollection,
    }
  },

  computed: {
    ...mapGetters(['mobile']),
  },

  watch: {
    $route() {
      const query = this.$route.query.q || {}

      this.form = {
        cargoShip: query.cargoShip || null,
        commodityIn: query.commodityIn || [],
        commodityTypeNotIn: query.commodityTypeNotIn || [],
        destinationCelestialObjectIn: query.destinationCelestialObjectIn || [],
        destinationStarsystemIn: query.destinationStarsystemIn || [],
        destinationStationIn: query.destinationStationIn || [],
        originCelestialObjectIn: query.originCelestialObjectIn || [],
        originStarsystemIn: query.originStarsystemIn || [],
        originStationIn: query.originStationIn || [],
        sorts: query.sorts || [],
      }

      const storedFilters = JSON.parse(JSON.stringify(this.form))

      if (!storedFilters.cargoShip) {
        delete storedFilters.cargoShip
      }
    },
  },

  mounted() {
    const query = this.$route.query.q || {}

    this.form = {
      cargoShip: query.cargoShip || null,
      commodityIn: query.commodityIn || [],
      commodityTypeNotIn: query.commodityTypeNotIn || [],
      destinationCelestialObjectIn: query.destinationCelestialObjectIn || [],
      destinationStarsystemIn: query.destinationStarsystemIn || [],
      destinationStationIn: query.destinationStationIn || [],
      originCelestialObjectIn: query.originCelestialObjectIn || [],
      originStarsystemIn: query.originStarsystemIn || [],
      originStationIn: query.originStationIn || [],
      sorts: query.sorts || [],
    }
  },
}
</script>
