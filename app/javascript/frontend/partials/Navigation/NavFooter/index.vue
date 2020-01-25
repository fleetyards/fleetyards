<template>
  <ul class="nav-bottom">
    <NavItem
      v-if="!mobile"
      :action="toggleSlim"
      :label="toggleSlimLabel"
      :icon="slim ? 'fal fa-chevron-double-right' : 'fal fa-chevron-double-left'"
    />
    <NavItem class="logo-menu">
      <img
        :src="require('images/favicon.png').default"
        class="logo-menu-image"
        alt="logo"
      >
      <transition name="fade-nav">
        <span
          v-if="!slim"
          class="logo-menu-label"
        >
          {{ $t('app') }}
        </span>
      </transition>
    </NavItem>
  </ul>
</template>

<script>
import { mapGetters } from 'vuex'
import NavItem from 'frontend/partials/Navigation/NavItem'

export default {
  components: {
    NavItem,
  },

  computed: {
    ...mapGetters([
      'mobile',
    ]),

    ...mapGetters('app', [
      'navSlim',
    ]),

    slim() {
      return this.navSlim && !this.mobile
    },

    toggleSlimLabel() {
      if (this.slim) {
        return this.$t('nav.toggleSlimExpand')
      }

      return this.$t('nav.toggleSlimCollapse')
    },
  },

  methods: {
    toggleSlim() {
      this.$store.commit('app/toggleSlimNav')
    },
  },
}
</script>
