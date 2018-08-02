<template>
  <form @submit.prevent="filter">
    <FilterGroup
      v-model="form.sortBy"
      :options="sortOptions"
      :label="t('labels.filters.cargoRoutes.sortBy')"
    />
    <FilterGroup
      v-if="modelOptions.length > 0"
      v-model="form.cargoShip"
      :options="modelOptions"
      :label="t('labels.filters.cargoRoutes.cargoShip')"
    />
    <FilterGroup
      v-if="tradeHubOptions.length > 0"
      :options="tradeHubOptions"
      v-model="form.tradeHubIn"
      :label="t('labels.filters.cargoRoutes.tradeHub')"
      multiple
    />
    <FilterGroup
      v-if="commodityOptions.length > 0"
      v-model="form.commodityIn"
      :options="commodityOptions"
      :label="t('labels.filters.cargoRoutes.commodity')"
      multiple
    />
    <FilterGroup
      v-if="planetOptions.length > 0"
      :options="planetOptions"
      v-model="form.planetIn"
      :label="t('labels.filters.cargoRoutes.planet')"
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
import CargoRoutes from 'frontend/mixins/CargoRoutes'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    FilterGroup,
    Btn,
  },
  mixins: [I18n, CargoRoutes, Filters],
  props: {
    hideButtons: {
      type: Boolean,
      default: false,
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
  methods: {
    filter() {
      const query = JSON.parse(JSON.stringify(this.form))
      Object.keys(query)
        .filter(key => !query[key] || query[key].length === 0)
        .forEach(key => delete query[key])
      this.$router.replace({
        name: this.$route.name,
        query: {
          q: query,
        },
      })
    },
  },
}
</script>
