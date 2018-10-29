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
      v-model="form.celestialObjectSlugIn"
      :label="t('labels.filters.stations.celestialObject')"
      :fetch="fetchCelestialObjects"
      name="celestial-object"
      value-attr="slug"
      paginated
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.starsystemSlugIn"
      :label="t('labels.filters.stations.starsystem')"
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
import Btn from 'frontend/components/Btn'

export default {
  components: {
    FilterGroup,
    Btn,
  },
  mixins: [I18n, Filters],
  data() {
    const query = this.$route.query.q || {}
    return {
      loading: false,
      form: {
        nameCont: query.nameCont,
        celestialObjectSlugIn: query.celestialObjectSlugIn || [],
        starsystemSlugIn: query.starsystemSlugIn || [],
      },
    }
  },
  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        nameCont: query.nameCont,
        celestialObjectSlugIn: query.celestialObjectSlugIn || [],
        starsystemSlugIn: query.starsystemSlugIn || [],
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
        query.q.nameOrSlugCont = search
      } else if (missingValue) {
        query.q.nameOrSlugIn = missingValue
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
        query.q.nameOrSlugCont = search
      } else if (missingValue) {
        query.q.nameOrSlugIn = missingValue
      } else if (page) {
        query.page = page
      }
      return this.$api.get('starsystems', query)
    },
  },
}
</script>
