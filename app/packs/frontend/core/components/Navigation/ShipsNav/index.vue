<template>
  <NavItem
    :label="$t('nav.models.index')"
    :submenu-active="active"
    menu-key="models-menu"
    icon="fad fa-starship"
  >
    <template slot="submenu">
      <NavItem
        :to="{
          name: 'models',
          query: filterFor('models'),
        }"
        :label="$t('nav.models.index')"
        :active="$route.name === 'models'"
        icon="fas fa-th"
        :exact="true"
      />
      <NavItem
        :to="{
          name: 'models-fleetchart',
          query: filterFor('models-fleetchart'),
        }"
        :label="$t('nav.models.fleetchart')"
        icon="fad fa-starship"
      />
      <NavItem divider />
      <NavItem
        :to="{
          name: 'models-compare',
        }"
        :label="$t('nav.compare.models')"
        icon="fad fa-exchange"
      />
    </template>
  </NavItem>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import NavItem from 'frontend/core/components/Navigation/NavItem'
import NavigationMixin from 'frontend/mixins/Navigation'

@Component<ShipsNav>({
  components: {
    NavItem,
  },
  mixins: [NavigationMixin],
})
export default class ShipsNav extends Vue {
  @Getter('filters') filters

  get active() {
    return ['models', 'models-fleetchart', 'models-compare'].includes(
      this.$route.name,
    )
  }

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
