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
    <BCollapse :id="`${menuKey}-sub-menu`" :visible="open" tag="ul">
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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import { BCollapse } from 'bootstrap-vue'
import NavItemInner from 'frontend/core/components/Navigation/NavItem/NavItemInner'
import NavigationMixin from 'frontend/mixins/Navigation'

@Component<NavItem>({
  components: {
    BCollapse,
    NavItemInner,
  },

  mixins: [NavigationMixin],
})
export default class NavItem extends Vue {
  open: boolean = false

  @Prop({ default: null }) to: Object | null

  @Prop({ default: null }) action: Function | null

  @Prop({ default: null }) href: string | null

  @Prop({ default: '' }) label: string

  @Prop({ default: null }) icon: string | null

  @Prop({ default: null }) image: string | null

  @Prop({ default: null }) menuKey: string | null

  @Prop({ default: false }) exact: boolean

  @Prop({ default: false }) divider: boolean

  @Prop({ default: false }) active: boolean

  @Prop({ default: false }) submenuActive: boolean

  get routeActive() {
    if (this.to) {
      return this.to.name === this.$route.name
    }
    return false
  }

  get tooltip() {
    if (!this.slim) {
      return null
    }

    return {
      content: this.label,
      classes: 'nav-item-tooltip',
      placement: 'right',
    }
  }

  get hasDefaultSlot() {
    return !!this.$slots.default
  }

  get hasSubmenuSlot() {
    return !!this.$slots.submenu
  }

  get matchedRoutes() {
    return this.$route.matched.map(route => route.name)
  }

  get navKey() {
    if (this.menuKey) {
      return this.menuKey
    }

    if (this.to) {
      return this.to.name
    }

    return 'nav-item'
  }

  @Watch('$route')
  onRouteChange() {
    this.checkRoutes()
  }

  @Watch('submenuActive')
  onSubmenuActiveChange() {
    this.checkRoutes()
  }

  mounted() {
    this.checkRoutes()
  }

  checkRoutes() {
    this.open = this.submenuActive
  }

  toggleMenu() {
    this.open = !this.open
  }
}
</script>

<style lang="scss">
@import 'index';
</style>
