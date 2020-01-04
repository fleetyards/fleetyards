<template>
  <li
    v-if="item.divider"
    class="nav-item divider"
  />
  <li
    v-else-if="item.submenu"
    :class="{
      active: submenuActive,
      open: open,
      'nav-item-slim': slim,
    }"
    class="nav-item sub-menu"
  >
    <a
      v-tooltip="tooltip"
      @click="toggleMenu"
    >
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :item="item"
        :slim="slim"
      />
      <transition name="fade-nav">
        <span
          v-if="!slim"
          class="submenu-icon"
        >
          <i class="fa fa-chevron-right" />
        </span>
      </transition>
    </a>
    <b-collapse
      :id="`${item.key}-sub-menu`"
      :visible="open"
      tag="ul"
    >
      <NavItem
        v-for="(submenuItem, index) in item.submenu"
        :key="`${item.key}-${index}`"
        :item="submenuItem"
        :slim="slim"
      />
    </b-collapse>
  </li>
  <li
    v-else-if="item.action"
    :class="{
      'nav-item-slim': slim,
    }"
    class="nav-item"
    @click="item.action"
  >
    <a v-tooltip="tooltip">
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :item="item"
        :slim="slim"
      />
    </a>
  </li>
  <router-link
    v-else-if="item.to"
    :to="item.to"
    :class="{
      'nav-item-slim': slim,
    }"
    class="nav-item"
    tag="li"
    :exact="exact"
  >
    <a v-tooltip="tooltip">
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :item="item"
        :slim="slim"
      />
    </a>
  </router-link>
  <li
    v-else
    :class="{
      'nav-item-slim': slim,
    }"
    class="nav-item"
  >
    <span>
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :item="item"
        :slim="slim"
      />
    </span>
  </li>
</template>

<script>
import NavItemInner from 'frontend/partials/Navigation/NavItem/NavItemInner'

export default {
  name: 'NavItem',

  components: {
    NavItemInner,
  },

  props: {
    item: {
      type: Object,
      required: true,
    },

    slim: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      open: false,
    }
  },

  computed: {
    tooltip() {
      if (!this.slim) {
        return null
      }

      return {
        content: this.item.label,
        classes: 'nav-item-tooltip',
        placement: 'right',
      }
    },

    hasDefaultSlot() {
      return !!this.$slots.default
    },

    exact() {
      return this.item.exact || false
    },

    matchedRoutes() {
      return this.$route.matched.map((route) => route.name)
    },

    alternativeRoute() {
      return this.$route.meta.nav
    },

    submenuActive() {
      return this.item.submenu
        && this.item.submenu.some((item) => this.matchedRoutes.includes(item.to?.name))
    },
  },

  watch: {
    $route() {
      this.checkRoutes()
    },
  },

  mounted() {
    this.checkRoutes()
  },

  methods: {
    checkRoutes() {
      this.open = this.submenuActive
    },

    toggleMenu() {
      this.open = !this.open
    },
  },
}
</script>

<style lang="scss">
  @import 'index';
</style>
