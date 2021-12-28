import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { debounce } from 'ts-debounce'

const getQuery = function getQuery(formData: Object) {
  const q = JSON.parse(JSON.stringify(formData))

  Object.keys(q)
    .filter((key) => !q[key] || q[key].length === 0)
    .forEach((key) => delete q[key])

  return q
}

@Component<FiltersMixin>({})
export default class FiltersMixin extends Vue {
  form: Object = {}

  filter: Function = debounce(this.debouncedFilter, 500)

  get isFilterSelected() {
    const query = JSON.parse(JSON.stringify(this.$route.query.q || {}))

    Object.keys(query)
      .filter((key) => !query[key] || query[key].length === 0)
      .forEach((key) => delete query[key])

    return Object.keys(query).length > 0
  }

  @Watch('form', {
    deep: true,
  })
  onFormChange() {
    this.filter()
  }

  resetFilter() {
    this.$router
      .replace({
        name: this.$route.name || undefined,
        query: {},
      })
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch((_err) => {})
  }

  debouncedFilter() {
    this.$router
      .replace({
        name: this.$route.name || undefined,
        query: {
          ...this.$route.query,
          q: getQuery(this.form),
        },
      })
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch((_err) => {})
  }
}
