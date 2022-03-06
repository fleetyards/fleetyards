<template>
  <div class="quick-search-bar">
    <form @submit.prevent="filter">
      <FormInput
        :id="$route.meta.search || 'search'"
        v-model="form[$route.meta.search]"
        :translation-key="`search.${$route.name}`"
        :no-label="true"
        :autofocus="!mobile"
      />
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import FormInput from '@/frontend/core/components/Form/FormInput/index.vue'
import debounce from 'lodash.debounce'

export default {
  name: 'SearchForm',

  components: {
    FormInput,
  },

  data() {
    return {
      filter: debounce(this.debouncedFilter, 500),
      form: {},
    }
  },

  computed: {
    ...mapGetters(['mobile']),
  },

  watch: {
    $route() {
      this.setupSearch()
    },

    form: {
      deep: true,
      handler() {
        this.filter()
      },
    },
  },

  mounted() {
    this.setupSearch()
  },

  methods: {
    debouncedFilter() {
      const query = {
        ...this.$route.query,
        ...this.form,
      }

      if (!query[this.$route.meta.search]) {
        delete query[this.$route.meta.search]
      }

      this.$router
        .replace({
          name: this.$route.name || undefined,
          query,
        })
        .catch((_err) => {})
    },

    setupSearch() {
      this.form = {
        [this.$route.meta.search]:
          this.$route.query[this.$route.meta.search] || null,
      }
    },
  },
}
</script>
