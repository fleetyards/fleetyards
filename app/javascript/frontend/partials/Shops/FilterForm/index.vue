<template>
  <form @submit.prevent="filter">
    <FormInput
      v-model="form.nameCont"
      :placeholder="$t('placeholders.filters.shops.name')"
      :aria-label="$t('placeholders.filters.shops.name')"
    />

    <FilterGroup
      v-model="form.modelIn"
      :label="$t('labels.filters.shops.model')"
      fetch-path="models"
      name="model"
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

    <FilterGroup
      v-model="form.equipmentIn"
      :label="$t('labels.filters.shops.equipment')"
      fetch-path="equipment"
      name="equipment"
      value-attr="slug"
      paginated
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.componentIn"
      :label="$t('labels.filters.shops.component')"
      fetch-path="components"
      name="component"
      value-attr="slug"
      paginated
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.shopTypeIn"
      :label="$t('labels.filters.shops.type')"
      :fetch="fetchShopTypes"
      name="type"
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
      :label="$t('labels.filters.shops.celestialObject')"
      fetch-path="celestial-objects"
      name="celestial-object"
      value-attr="slug"
      paginated
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.starsystemIn"
      :label="$t('labels.filters.shops.starsystem')"
      fetch-path="starsystems"
      name="starsystem"
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
import Filters from 'frontend/mixins/Filters'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import FormInput from 'frontend/components/Form/FormInput'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    FilterGroup,
    FormInput,
    Btn,
  },
  mixins: [Filters],
  data() {
    const query = this.$route.query.q || {}
    return {
      loading: false,
      form: {
        nameCont: query.nameCont,
        modelIn: query.modelIn || [],
        commodityIn: query.commodityIn || [],
        equipmentIn: query.equipmentIn || [],
        componentIn: query.componentIn || [],
        stationIn: query.stationIn || [],
        celestialObjectIn: query.celestialObjectIn || [],
        starsystemIn: query.starsystemIn || [],
        shopTypeIn: query.shopTypeIn || [],
      },
    }
  },
  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        nameCont: query.nameCont,
        modelIn: query.modelIn || [],
        commodityIn: query.commodityIn || [],
        equipmentIn: query.equipmentIn || [],
        componentIn: query.componentIn || [],
        stationIn: query.stationIn || [],
        celestialObjectIn: query.celestialObjectIn || [],
        starsystemIn: query.starsystemIn || [],
        shopTypeIn: query.shopTypeIn || [],
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
    fetchShopTypes() {
      return this.$api.get('shops/shop-types')
    },
  },
}
</script>
