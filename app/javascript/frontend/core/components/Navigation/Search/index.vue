<template>
  <div class="quick-search-bar">
    <form @submit.prevent="filter">
      <FormInput
        :id="$route.meta.search || 'search'"
        v-model="form[$route.meta.search]"
        :translation-key="`search.${$route.name}`"
        :no-label="true"
        :clearable="true"
        :autofocus="true"
      />
    </form>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import FormInput from 'frontend/core/components/Form/FormInput'
import { debounce } from 'ts-debounce'

@Component<SearchForm>({
  components: {
    FormInput,
  },
})
export default class SearchForm extends Vue {
  form: Object = {}

  filter: Function = debounce(this.debouncedFilter, 500)

  mounted() {
    this.setupSearch()
  }

  @Watch('form', {
    deep: true,
  })
  onFormChange() {
    this.filter()
  }

  @Watch('$route')
  onRouteChange() {
    this.setupSearch()
  }

  setupSearch() {
    this.form = {
      [this.$route.meta.search]:
        this.$route.query[this.$route.meta.search] || null,
    }
  }

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
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch(_err => {})
  }
}
</script>
