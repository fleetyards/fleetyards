<template>
  <li v-if="divider" class="nav-item divider" />
  <li
    v-else-if="hasSubmenuSlot"
    :class="{
      'active': active || submenuActive,
      'open': open,
      'nav-item-slim': slim,
    }"
    :data-test="`nav-${navKey}`"
    class="nav-item sub-menu"
  >
    <a v-tooltip="tooltip" @click="toggleMenu">
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :label="label"
        :icon="icon"
        :image="image"
        :slim="slim"
      />
      <transition name="fade-nav">
        <span v-if="!slim" class="submenu-icon">
          <i class="fa fa-chevron-right" />
        </span>
      </transition>
    </a>
    <b-collapse :id="`${menuKey}-sub-menu`" :visible="open" tag="ul">
      <slot name="submenu" />
    </b-collapse>
  </li>
  <li
    v-else-if="action"
    :class="{
      'nav-item-slim': slim,
    }"
    :data-test="`nav-${navKey}`"
    class="nav-item"
    @click="action"
  >
    <a v-tooltip="tooltip">
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :label="label"
        :icon="icon"
        :image="image"
        :slim="slim"
      />
    </a>
  </li>
  <router-link
    v-else-if="to"
    :to="to"
    :class="{
      'active': active,
      'nav-item-slim': slim,
    }"
    :data-test="`nav-${navKey}`"
    class="nav-item"
    tag="li"
    :exact="exact"
  >
    <a v-tooltip="tooltip">
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :label="label"
        :icon="icon"
        :image="image"
        :slim="slim"
      />
    </a>
  </router-link>
  <li
    v-else-if="href"
    :class="{
      'nav-item-slim': slim,
    }"
    class="nav-item"
    :data-test="`nav-${navKey}`"
  >
    <a v-tooltip="tooltip" :href="href" target="_blank" rel="noopener">
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :label="label"
        :icon="icon"
        :image="image"
        :slim="slim"
      />
    </a>
  </li>
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
        :label="label"
        :icon="icon"
        :image="image"
        :slim="slim"
      />
    </span>
  </li>
</template>

<script>
import NavItemInner from 'frontend/partials/Navigation/NavItem/NavItemInner'
import NavigationMixin from 'frontend/mixins/Navigation'

export default {
  name: 'NavItem',

  components: {
    NavItemInner,
  },

  mixins: [NavigationMixin],

  props: {
    to: {
      type: Object,
      default: null,
    },

    action: {
      type: Function,
      default: null,
    },

    href: {
      type: String,
      default: null,
    },

    label: {
      type: String,
      default: '',
    },

    icon: {
      type: String,
      default: null,
    },

    image: {
      type: String,
      default: null,
    },

    menuKey: {
      type: String,
      default: null,
    },

    exact: {
      type: Boolean,
      default: false,
    },

    divider: {
      type: Boolean,
      default: false,
    },

    active: {
      type: Boolean,
      default: false,
    },

    submenuActive: {
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
        content: this.label,
        classes: 'nav-item-tooltip',
        placement: 'right',
      }
    },

    hasDefaultSlot() {
      return !!this.$slots.default
    },

    hasSubmenuSlot() {
      return !!this.$slots.submenu
    },

    matchedRoutes() {
      return this.$route.matched.map(route => route.name)
    },

    navKey() {
      if (this.menuKey) {
        return this.menuKey
      }

      if (this.to) {
        return this.to.name
      }

      return 'nav-item'
    },
  },

  watch: {
    $route() {
      this.checkRoutes()
    },

    submenuActive() {
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
