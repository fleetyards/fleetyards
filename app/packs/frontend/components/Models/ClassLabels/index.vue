<template>
  <BtnDropdown
    v-if="mobile"
    :mobile-block="true"
    size="small"
    class="labels-dropdown"
  >
    <template slot="label">Classifications</template>
    <template slot="default">
      <Btn
        v-for="classification in countData"
        :key="`dropdown-${classification.name}`"
        variant="dropdown"
        class="labels-dropdown-item"
        :class="{
          active: isActive(classification.name),
        }"
        @click.native="filter(classification.name)"
      >
        {{ classification.label }}
        <span class="label-count">{{ classification.count }}</span>
      </Btn>
    </template>
  </BtnDropdown>
  <div v-else class="labels">
    <transition-group name="fade-list" appear>
      <a
        v-for="classification in countData"
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
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import Btn from 'frontend/core/components/Btn'
import { mapGetters } from 'vuex'

export default {
  name: 'ModelClassLabels',

  components: {
    BtnDropdown,
    Btn,
  },

  props: {
    countData: {
      type: Array,
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
    ...mapGetters(['mobile']),

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
