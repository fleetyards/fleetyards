<template>
  <div class="labels">
    <transition-group
      name="fade-list"
      appear
    >
      <a
        v-for="classification in countData.classifications"
        :key="classification.name"
        :class="{
          'label-link': filterKey,
          'active': isActive(classification.name),
        }"
        class="label fade-list-item"
        @click="filter(classification.name)"
      >
        <span class="label-inner">
          {{ classification.label }}: {{ classification.count }}
        </span>
      </a>
    </transition-group>
  </div>
</template>

<script>
export default {
  props: {
    countData: {
      type: Object,
      required: true,
    },
    filterKey: {
      type: String,
      default: '',
    },
    label: {
      type: String,
      default: '',
    },
  },
  computed: {
    allLabel() {
      return this.label || this.$t('labels.fleet.size')
    },
  },
  methods: {
    filter(filter) {
      if (!this.filterKey) {
        return
      }
      const query = JSON.parse(JSON.stringify(this.$route.query.q || {}))

      if ((query[this.filterKey] || []).includes(filter)) {
        const index = query[this.filterKey].findIndex((item) => item === filter)
        if (index > -1) {
          query[this.filterKey].splice(index, 1)
        }
      } else {
        if (!query[this.filterKey]) {
          query[this.filterKey] = []
        }
        query[this.filterKey].push(filter)
      }

      this.$router.replace({
        name: this.$route.name,
        query: {
          q: query,
        },
      })
    },
    isActive(classification) {
      if (!this.$route.query.q) {
        return false
      }

      const classFilter = this.$route.query.q[this.filterKey]
      if (!classFilter) {
        return false
      }

      if (classFilter.includes(classification)) {
        return true
      }

      return false
    },
  },
}
</script>
