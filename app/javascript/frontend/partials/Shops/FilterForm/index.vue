<template>
  <form @submit.prevent="filter">
    <div class="form-group">
      <input
        v-model="form.nameCont"
        :placeholder="t('placeholders.filters.shops.name')"
        type="text"
        class="form-control form-control-filter"
      >
      <a
        v-if="form.nameCont"
        class="btn btn-clear"
        @click="clearName"
        v-html="'&times;'"
      />
    </div>
    <div class="form-group">
      <label :for="idFor('shops-commodity-name')">
        {{ t('labels.filters.shops.commodityName') }}
      </label>
      <input
        :id="idFor('shops-commodity-name')"
        v-model="form.commodityNameCont"
        :placeholder="t('placeholders.filters.shops.commodityName')"
        type="text"
        class="form-control form-control-filter"
      >
      <a
        v-if="form.commodityNameCont"
        class="btn btn-clear"
        @click="clearCommodityName"
        v-html="'&times;'"
      />
    </div>
    <FilterGroup
      v-model="form.shopTypeIn"
      :label="t('labels.filters.shops.type')"
      :fetch="fetchShopTypes"
      name="type"
      multiple
    />
    <FilterGroup
      v-model="form.stationIn"
      :label="t('labels.filters.shops.station')"
      :fetch="fetchStations"
      name="station"
      value-attr="slug"
      paginated
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.celestialObjectIn"
      :label="t('labels.filters.shops.celestialObject')"
      :fetch="fetchCelestialObjects"
      name="celestial-object"
      value-attr="slug"
      paginated
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.starsystemIn"
      :label="t('labels.filters.shops.starsystem')"
      :fetch="fetchStarsystems"
      name="starsystem"
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
        commodityNameCont: query.commodityNameCont,
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
        commodityNameCont: query.commodityNameCont,
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
    clearName() {
      this.form.nameCont = null
    },
    clearCommodityName() {
      this.form.commodityNameCont = null
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
      return this.$api.get('stations', query)
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
    fetchShopTypes() {
      return this.$api.get('shops/shop-types')
    },
  },
}
</script>
