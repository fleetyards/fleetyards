<template>
  <li
    v-if="item.divider"
    class="nav-item divider"
  />
  <li
    v-else-if="item.submenu"
    :class="{
      active,
      open: open,
      'nav-item-slim': slim,
    }"
    class="nav-item sub-menu"
  >
    <a @click="toggleMenu">
      <slot v-if="hasDefaultSlot" />
      <template v-else>
        <i
          v-if="item.icon"
          v-tooltip.bottom-end="item.label"
          :class="{
            [item.icon]: true,
          }"
        />
        <transition name="fade-nav">
          <span v-if="!slim">{{ item.label }}</span>
        </transition>
      </template>
      <transition name="fade-nav">
        <i
          v-if="!slim"
          class="fa fa-chevron-right"
        />
      </transition>
    </a>
    <b-collapse
      :id="`${item.submenuId}-sub-menu`"
      :visible="open"
      tag="ul"
    >
      <NavItem
        v-for="(submenuItem, index) in item.submenu"
        :key="`${item.submenuId}-${index}`"
        :item="submenuItem"
        :slim="slim"
      />
    </b-collapse>
  </li>
  <li
    v-else-if="item.action"
    :class="{
      active,
      'nav-item-slim': slim,
    }"
    class="nav-item"
    @click="item.action"
  >
    <a>
      <slot v-if="hasDefaultSlot" />
      <template v-else>
        <i
          v-if="item.icon"
          v-tooltip.bottom-end="item.label"
          :class="{
            [item.icon]: true,
          }"
        />
        <transition name="fade-nav">
          <span v-if="!slim">{{ item.label }}</span>
        </transition>
      </template>
    </a>
  </li>
  <router-link
    v-else-if="item.to"
    :to="item.to"
    :class="{
      active,
      'nav-item-slim': slim,
    }"
    class="nav-item"
    active-class="router-active"
    tag="li"
    :exact="exact"
  >
    <a>
      <slot v-if="hasDefaultSlot" />
      <template v-else>
        <i
          v-if="item.icon"
          v-tooltip.bottom-end="item.label"
          :class="{
            [item.icon]: true,
          }"
        />
        <transition name="fade-nav">
          <span v-if="!slim">{{ item.label }}</span>
        </transition>
      </template>
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
      <template v-else>
        <i
          v-if="item.icon"
          v-tooltip.bottom-end="item.label"
          :class="{
            [item.icon]: true,
          }"
        />
        <transition name="fade-nav">
          <span v-if="!slim">{{ item.label }}</span>
        </transition>
      </template>
    </span>
  </li>
</template>

<script>
export default {
  name: 'NavItem',

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
    hasDefaultSlot() {
      return !!this.$slots.default
    },

    active() {
      return this.item.active || false
    },

    exact() {
      return this.item.exact || false
    },

    submenuActive() {
      return this.item.submenu && this.item.submenu.some((item) => item.active)
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
      this.open = this.active || this.submenuActive
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
