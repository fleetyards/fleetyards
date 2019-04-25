<template>
  <form @submit.prevent="filter">
    <div class="form-group">
      <input
        v-model="form.nameCont"
        :placeholder="t('placeholders.filters.vehicles.name')"
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
  </form>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Filters from 'frontend/mixins/Filters'

export default {
  mixins: [I18n, Filters],
  props: {
    hangarGroupsOptions: {
      type: Array,
      default() {
        return []
      },
    },
  },
  data() {
    const query = this.$route.query.q || {}
    return {
      form: {
        nameCont: query.nameCont,
      },
    }
  },
  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        nameCont: query.nameCont,
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
  },
}
</script>
