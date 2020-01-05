<template>
  <div class="quick-search-bar">
    <form @submit.prevent="filter">
      <FormInput
        v-model="form[$route.meta.quickSearch]"
        :placeholder="$t(`placeholders.quicksearch.${$route.name}`)"
        :aria-label="$t(`placeholders.quicksearch.${$route.name}`)"
        :name="$route.meta.quickSearch || 'quicksearch'"
        autofocus
      />
    </form>
  </div>
</template>

<script>
import Filters from 'frontend/mixins/Filters'
import FormInput from 'frontend/components/Form/FormInput'

export default {
  components: {
    FormInput,
  },

  mixins: [
    Filters,
  ],

  data() {
    const query = this.queryParams()

    query[this.$route.meta.quickSearch] = query[this.$route.meta.quickSearch] || null

    return {
      form: query,
    }
  },

  watch: {
    $route() {
      const query = this.queryParams()

      query[this.$route.meta.quickSearch] = query[this.$route.meta.quickSearch] || null

      this.form = query
    },
    form: {
      handler() {
        this.filter()
      },
      deep: true,
    },
  },

  methods: {
    queryParams() {
      return JSON.parse(JSON.stringify(this.$route.query.q || {}))
    },
  },
}
</script>
