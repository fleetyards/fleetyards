<template>
  <NavItem
    :item="item"
    :slim="slim"
  >
    <span
      :class="{
        'fleets-nav-item-icon-slim': slim
      }"
      class="fleets-nav-item-icon"
    >
      <i class="fad fa-rocket-launch" />
      <i class="fad fa-rocket-launch" />
    </span>
    <transition name="fade-nav">
      <span v-if="!slim">{{ item.label }}</span>
    </transition>
  </NavItem>
</template>

<script>
import NavItem from 'frontend/partials/Navigation/NavItem'

export default {
  name: 'FleetNavItem',

  components: {
    NavItem,
  },

  props: {
    item: {
      type: Object,
      required: true,
    },

    slim: {
      type: Boolean,
      required: false,
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
