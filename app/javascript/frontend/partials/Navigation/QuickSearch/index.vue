<template>
  <div class="quick-search-bar">
    <form @submit.prevent="filter">
      <FormInput
        v-model="form[$route.meta.quickSearch]"
        :placeholder="t(`placeholders.quicksearch.${$route.name}`)"
        :aria-label="t(`placeholders.quicksearch.${$route.name}`)"
        autofocus
      />
    </form>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Filters from 'frontend/mixins/Filters'
import FormInput from 'frontend/components/Form/FormInput'

export default {
  components: {
    FormInput,
  },
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
}
</script>
