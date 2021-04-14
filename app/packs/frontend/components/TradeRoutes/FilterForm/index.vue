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

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import Filters from 'frontend/mixins/Filters'
import FilterGroup from 'frontend/core/components/Form/FilterGroup'
import CollectionFilterGroup from 'frontend/core/components/Form/CollectionFilterGroup'
import Btn from 'frontend/core/components/Btn'
import { Getter } from 'vuex-class'
import celestialObjectCollection from 'frontend/api/collections/CelestialObjects'
import starsystemCollection from 'frontend/api/collections/Starsystems'

@Component<TradeRoutesFilterForm>({
  components: {
    FilterGroup,
    CollectionFilterGroup,
    Btn,
  },
  mixins: [Filters],
})
export default class TradeRoutesFilterForm extends Vue {
  celestialObjectCollection: CelestialObjectCollection = celestialObjectCollection

  starsystemCollection: StarsystemCollection = starsystemCollection

  form: TradeRoutesFilters

  @Getter('mobile') mobile

  mounted() {
    const query = this.$route.query.q || {}

    this.form = {
      cargoShip: query.cargoShip || null,
      commodityIn: query.commodityIn || [],
      commodityTypeNotIn: query.commodityTypeNotIn || [],
      originStationIn: query.originStationIn || [],
      destinationStationIn: query.destinationStationIn || [],
      originCelestialObjectIn: query.originCelestialObjectIn || [],
      destinationCelestialObjectIn: query.destinationCelestialObjectIn || [],
      originStarsystemIn: query.originStarsystemIn || [],
      destinationStarsystemIn: query.destinationStarsystemIn || [],
      sorts: query.sorts || [],
    }
  }

  @Watch('$route')
  onRouteChange() {
    const query = this.$route.query.q || {}

    this.form = {
      cargoShip: query.cargoShip || null,
      commodityIn: query.commodityIn || [],
      commodityTypeNotIn: query.commodityTypeNotIn || [],
      originStationIn: query.originStationIn || [],
      destinationStationIn: query.destinationStationIn || [],
      originCelestialObjectIn: query.originCelestialObjectIn || [],
      destinationCelestialObjectIn: query.destinationCelestialObjectIn || [],
      originStarsystemIn: query.originStarsystemIn || [],
      destinationStarsystemIn: query.destinationStarsystemIn || [],
      sorts: query.sorts || [],
    }

    const storedFilters = JSON.parse(JSON.stringify(this.form))

    if (!storedFilters.cargoShip) {
      delete storedFilters.cargoShip
    }
  }
}
</script>
