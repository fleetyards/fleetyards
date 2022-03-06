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
    <BCollapse
      v-if="submenuDirection === 'up'"
      :id="`${menuKey}-sub-menu`"
      :visible="open"
      tag="ul"
    >
      <slot name="submenu" />
    </BCollapse>
    <button v-tooltip="tooltip" @click="toggleMenu">
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :label="label"
        :icon="icon"
        :image="image"
        :avatar="avatar"
        :slim="slim"
      />
      <span
        v-if="!slim"
        class="submenu-icon"
        :class="{ 'submenu-icon-up': submenuDirection === 'up' }"
      >
        <i class="fal fa-chevron-right" />
      </span>
    </button>
    <BCollapse
      v-if="submenuDirection === 'down'"
      :id="`${menuKey}-sub-menu`"
      :visible="open"
      tag="ul"
    >
      <slot name="submenu" />
    </BCollapse>
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
        :avatar="avatar"
        :slim="slim"
      />
    </a>
  </li>
  <router-link
    v-else-if="to"
    v-slot="{ href: linkHref, navigate }"
    :to="to"
    :class="{
      'active': active || routeActive,
      'nav-item-slim': slim,
    }"
    :data-test="`nav-${navKey}`"
    class="nav-item"
    :exact="exact"
    :custom="true"
  >
    <li role="link" @click="navigate" @keypress.enter="navigate">
      <a v-tooltip="tooltip" :href="linkHref">
        <slot v-if="hasDefaultSlot" />
        <NavItemInner
          v-else
          :label="label"
          :icon="icon"
          :image="image"
          :avatar="avatar"
          :slim="slim"
        />
      </a>
    </li>
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
        :avatar="avatar"
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
        :avatar="avatar"
        :slim="slim"
      />
    </span>
  </li>
</template>

<script>
import { mapGetters } from 'vuex'
import { BCollapse } from 'bootstrap-vue'
import NavItemInner from '@/frontend/core/components/Navigation/NavItem/NavItemInner/index.vue'

export default {
  name: 'NavItem',

  components: {
    BCollapse,
    NavItemInner,
  },

  props: {
    action: {
      type: [Object, Function],
      default: null,
    },

    active: {
      type: Boolean,
      default: false,
    },

    avatar: {
      type: Boolean,
      default: false,
    },

    divider: {
      type: Boolean,
      default: false,
    },

    exact: {
      type: Boolean,
      default: false,
    },

    href: {
      default: null,
      type: String,
    },

    icon: {
      type: String,
      default: null,
    },

    image: {
      type: String,
      default: null,
    },

    label: {
      type: String,
      default: null,
    },

    menuKey: {
      type: String,
      default: null,
    },

    submenuActive: {
      default: false,
      type: Boolean,
    },

    submenuDirection: {
      default: 'down',
      type: String,
      validator(value) {
        return ['down', 'up'].indexOf(value) !== -1
      },
    },

    to: {
      type: Object,
      default: null,
    },
  },

  data() {
    return {
      open: false,
    }
  },

  computed: {
    ...mapGetters(['mobile']),

    ...mapGetters('app', ['navSlim']),

    hasDefaultSlot() {
      return !!this.$slots.default
    },

    hasSubmenuSlot() {
      return !!this.$slots.submenu
    },

    matchedRoutes() {
      return this.$route.matched.map((route) => route.name)
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

    routeActive() {
      if (this.to) {
        return this.to.name === this.$route.name
      }
      return false
    },

    slim() {
      return this.navSlim && !this.mobile
    },

    tooltip() {
      if (!this.slim) {
        return null
      }

      return {
        classes: 'nav-item-tooltip',
        content: this.label,
        placement: 'right',
      }
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
@import 'index.scss';
</style>
