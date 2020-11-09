<template>
  <header class="navigation-header">
    <button
      v-if="mobile"
      :class="{
        collapsed: navCollapsed,
      }"
      class="nav-toggle"
      type="button"
      aria-label="Toggle Navigation"
      @click.stop.prevent="toggle"
    >
      <span class="sr-only">
        {{ $t('labels.toggleNavigation') }}
      </span>
      <span class="icon-bar top-bar" />
      <span class="icon-bar middle-bar" />
      <span class="icon-bar bottom-bar" />
    </button>
    <div
      v-if="nodeEnv && !mobile"
      :class="{
        'spacing-right': this.$route.name === 'home',
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
  </header>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Getter, Action } from 'vuex-class'
import QuickSearch from 'frontend/core/components/Navigation/QuickSearch'

@Component<NavigationHeader>({
  components: {
    QuickSearch,
  },
})
export default class NavigationHeader extends Vue {
  @Getter('mobile') mobile!: boolean

  @Getter('navCollapsed', { namespace: 'app' }) navCollapsed!: boolean

  @Getter('gitRevision', { namespace: 'app' }) gitRevision!: string

  @Action('toggleNav', { namespace: 'app' }) toggle

  get environmentLabelClasses() {
    const cssClasses = ['pill']

    if (window.NODE_ENV === 'staging') {
      cssClasses.push('pill-warning')
    } else if (window.NODE_ENV === 'production') {
      cssClasses.push('pill-danger')
    }

    return cssClasses
  }

  get nodeEnv() {
    if (window.NODE_ENV === 'production') {
      return null
    }

    return (window.NODE_ENV || '').toUpperCase()
  }
}
</script>
