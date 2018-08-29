<template>
  <form @submit.prevent="filter">
    <FilterGroup
      v-model="form.sortBy"
      :options="sortOptions"
      :label="t('labels.filters.cargoRoutes.sortBy')"
      :name="`${prefix}-sort`"
    />
    <FilterGroup
      v-if="modelOptions.length > 0"
      v-model="form.cargoShip"
      :options="modelOptions"
      :label="t('labels.filters.cargoRoutes.cargoShip')"
      :name="`${prefix}-models`"
      searchable
    />
    <FilterGroup
      v-if="tradeHubOptions.length > 0"
      :options="tradeHubOptions"
      v-model="form.tradeHubIn"
      :label="t('labels.filters.cargoRoutes.tradeHub')"
      :name="`${prefix}-tradehubs`"
      searchable
      multiple
    />
    <FilterGroup
      v-if="commodityOptions.length > 0"
      v-model="form.commodityIn"
      :options="commodityOptions"
      :label="t('labels.filters.cargoRoutes.commodity')"
      :name="`${prefix}-commodities`"
      searchable
      multiple
    />
    <FilterGroup
      v-if="planetOptions.length > 0"
      :options="planetOptions"
      v-model="form.planetIn"
      :name="`${prefix}-planets`"
      :label="t('labels.filters.cargoRoutes.planet')"
      searchable
      multiple
    />
    <Btn
      v-if="!hideButtons"
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
import Btn from 'frontend/components/Btn'

export default {
  components: {
    FilterGroup,
    Btn,
  },
  mixins: [I18n, Filters],
  props: {
    tradeHubs: {
      type: Array,
      default() {
        return []
      },
    },
    commodities: {
      type: Array,
      default() {
        return []
      },
    },
    modelOptions: {
      type: Array,
      default() {
        return []
      },
    },
    hideButtons: {
      type: Boolean,
      default: false,
    },
    prefix: {
      type: String,
      default: 'filter',
    },
  },
  data() {
    const query = this.$route.query.q || {}
    return {
      sortOptions: [{
        name: this.t('labels.filters.cargoRoutes.sortByValues.percent'),
        value: 'percent',
      }, {
        name: this.t('labels.filters.cargoRoutes.sortByValues.profit'),
        value: 'profit',
      }],
      form: {
        sortBy: query.sortBy || 'percent',
        cargoShip: query.cargoShip || null,
        tradeHubIn: query.tradeHubIn || [],
        commodityIn: query.commodityIn || [],
        planetIn: query.planetIn || [],
      },
    }
  },
  computed: {
    tradeHubOptions() {
      return this.tradeHubs.map(item => ({
        value: item.slug,
        name: item.name,
      }))
    },
    commodityOptions() {
      return this.commodities.map(item => ({
        value: item.slug,
        name: item.name,
      }))
    },
    planetOptions() {
      const planets = this.tradeHubs.map(item => item.planet)
      const uniqPlanets = [...new Set(planets)]
      return uniqPlanets.map(item => ({
        value: item,
        name: item,
      }))
    },
  },
  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        sortBy: query.sortBy || 'percent',
        cargoShip: query.cargoShip || null,
        commodityIn: query.commodityIn || [],
        tradeHubIn: query.tradeHubIn || [],
        planetIn: query.planetIn || [],
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
