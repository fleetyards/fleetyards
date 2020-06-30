<template>
  <div class="col-12 fade-list-item quick-filter">
    <form @submit.prevent="filter">
      <div class="row">
        <div class="col-12 col-md-4">
          <FilterGroup
            v-model="form.originIn"
            :label="$t('labels.filters.tradeRoutes.origin')"
            fetch-path="stations?quickfilter-origin"
            name="origin"
            value-attr="slug"
            :paginated="true"
            :searchable="true"
            :multiple="true"
            :no-label="true"
          />
        </div>
        <div class="col-12 col-md-4">
          <FilterGroup
            v-model="form.commodityIn"
            :label="$t('labels.filters.shops.commodity')"
            fetch-path="commodities?quickfilter"
            name="commodity"
            value-attr="slug"
            :paginated="true"
            :searchable="true"
            :multiple="true"
            :no-label="true"
          />
        </div>
        <div class="col-12 col-md-4">
          <FilterGroup
            v-model="form.destinationIn"
            :label="$t('labels.filters.tradeRoutes.destination')"
            fetch-path="stations?quickfilter-destination"
            name="destination"
            value-attr="slug"
            :paginated="true"
            :searchable="true"
            :multiple="true"
            :no-label="true"
          />
        </div>
      </div>
    </form>
  </div>
</template>

<script>
import Filters from 'frontend/mixins/Filters'
import FilterGroup from 'frontend/core/components/Form/FilterGroup'

export default {
  components: {
    FilterGroup,
  },

  mixins: [Filters],

  data() {
    const query = this.queryParams()

    query.originIn = query.originIn || []
    query.commodityIn = query.commodityIn || []
    query.destinationIn = query.destinationIn || []

    return {
      form: query,
    }
  },

  watch: {
    $route() {
      const query = this.queryParams()

      query.originIn = query.originIn || []
      query.commodityIn = query.commodityIn || []
      query.destinationIn = query.destinationIn || []

      this.form = query
    },
  },

  methods: {
    queryParams() {
      return JSON.parse(JSON.stringify(this.$route.query.q || {}))
    },
  },
}
</script>

<style lang="scss" scoped>
.quick-filter {
  margin-bottom: 20px;
}
</style>
