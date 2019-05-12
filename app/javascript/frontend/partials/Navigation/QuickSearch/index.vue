<template>
  <div class="quick-search-bar">
    <form @submit.prevent="filter">
      <div class="form-group">
        <input
          v-model="form[$route.meta.quickSearch]"
          :placeholder="t(`placeholders.quicksearch.${$route.name}`)"
          type="text"
          class="form-control form-control-filter"
        >
        <a
          v-if="form[$route.meta.quickSearch]"
          class="btn btn-clear"
          @click="clear"
          v-html="'&times;'"
        />
      </div>
    </form>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Filters from 'frontend/mixins/Filters'

export default {
  mixins: [I18n, Filters],
  data() {
    const query = this.$route.query.q || {}
    const form = {}
    form[this.$route.meta.quickSearch] = query[this.$route.meta.quickSearch]
    return {
      form,
    }
  },
  watch: {
    $route() {
      const query = this.$route.query.q || {}
      const form = {}
      form[this.$route.meta.quickSearch] = query[this.$route.meta.quickSearch]
      this.form = form
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
    clear() {
      this.form[this.$route.meta.quickSearch] = null
    },
  },
}
</script>
