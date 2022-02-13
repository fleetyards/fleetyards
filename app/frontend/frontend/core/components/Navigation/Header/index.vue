<template>
  <header class="navigation-header">
    <div
      v-if="nodeEnv && !mobile"
      :class="{
        'spacing-right': $route.name === 'home',
      }"
      class="environment-label"
    >
      <span :class="environmentLabelClasses">
        <i class="far fa-info-circle" />
        {{ nodeEnv }}
      </span>
      <span class="git-revision" :class="environmentLabelClasses">
        <i class="far fa-fingerprint" />
        {{ gitRevision }}
      </span>
    </div>
    <QuickSearch v-if="$route.meta.quickSearch" />
    <Search v-if="$route.meta.search" />
  </header>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import QuickSearch from '@/frontend/core/components/Navigation/QuickSearch/index.vue'
import Search from '@/frontend/core/components/Navigation/Search/index.vue'

export default {
  name: 'NavigationHeader',

  components: {
    QuickSearch,
    Search,
  },

  computed: {
    ...mapGetters(['mobile']),
    ...mapGetters('app', ['navCollapsed', 'gitRevision']),

    environmentLabelClasses() {
      const cssClasses = ['pill']

      if (window.NODE_ENV === 'staging') {
        cssClasses.push('pill-warning')
      } else if (window.NODE_ENV === 'production') {
        cssClasses.push('pill-danger')
      }

      return cssClasses
    },

    nodeEnv() {
      if (window.NODE_ENV === 'production') {
        return null
      }

      return (window.NODE_ENV || '').toUpperCase()
    },
  },

  methods: {
    ...mapActions('app', {
      toggle: 'toggleNav',
    }),
  },
}
</script>
