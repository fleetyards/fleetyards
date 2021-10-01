<template>
  <div class="navigation-mobile noselect">
    <div class="navigation-items">
      <Btn variant="link" :inline="true" :to="{ name: 'home' }" :exact="true">
        <i class="fad fa-home-alt" />
      </Btn>
      <portal-target name="navigation-mobile-extras">
        <Btn variant="link" :inline="true">
          <span />
        </Btn>
      </portal-target>
      <Btn variant="link" :inline="true" :to="{ name: 'search' }">
        <i class="fa fa-search" />
      </Btn>
      <Btn
        v-if="isAuthenticated || !hangarPreview"
        variant="link"
        :inline="true"
        :to="{
          name: 'hangar',
          query: filterFor('hangar'),
        }"
      >
        <i class="fad fa-bookmark" />
      </Btn>
      <Btn
        v-else
        variant="link"
        :inline="true"
        :to="{ name: 'hangar-preview' }"
      >
        <i class="fad fa-bookmark" />
      </Btn>
      <button
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
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Getter, Action } from 'vuex-class'
import Btn from 'frontend/core/components/Btn'

@Component<NavigationHeader>({
  components: {
    Btn,
  },
})
export default class NavigationHeader extends Vue {
  @Getter('mobile') mobile

  @Getter('filters') filters

  @Getter('navCollapsed', { namespace: 'app' }) navCollapsed!: boolean

  @Getter('isAuthenticated', { namespace: 'session' }) isAuthenticated!: boolean

  @Getter('preview', { namespace: 'hangar' }) hangarPreview

  @Action('toggleNav', { namespace: 'app' }) toggle

  filterFor(route) {
    // // TODO: disabled until vue-router supports navigation to same route
    // return null
    if (!this.filters[route]) {
      return null
    }

    return {
      q: this.filters[route],
    }
  }
}
</script>
