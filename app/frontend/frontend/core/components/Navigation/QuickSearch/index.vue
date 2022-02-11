<template>
  <div class="quick-search-bar">
    <form @submit.prevent="filter">
      <FormInput
        :id="$route.meta.quickSearch || 'quicksearch'"
        v-model="form[$route.meta.quickSearch]"
        :translation-key="`quicksearch.${$route.name}`"
        :no-label="true"
        :autofocus="!mobile"
        :clearable="true"
      />
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import Filters from '@/frontend/mixins/Filters'
import FormInput from '@/frontend/core/components/Form/FormInput/index.vue'

export default {
  name: 'QuickSearch',

  components: {
    FormInput,
  },

  mixins: [Filters],

  data() {
    return {
      form: {},
    }
  },

  computed: {
    ...mapGetters(['mobile']),
  },

  watch: {
    $route() {
      const query = this.queryParams()

      query[this.$route.meta.quickSearch] =
        query[this.$route.meta.quickSearch] || null

      this.form = query
    },
  },

  mounted() {
    const query = this.queryParams()

    query[this.$route.meta.quickSearch] =
      query[this.$route.meta.quickSearch] || null

    this.form = query
  },

  methods: {
    queryParams() {
      return JSON.parse(JSON.stringify(this.$route.query.q || {}))
    },
  },
}
</script>
