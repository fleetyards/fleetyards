<template>
  <NavItem
    v-if="currentUser"
    :class="{
      'user-menu-slim': slim,
    }"
    :submenu-active="active"
    menu-key="user-menu"
    class="user-menu"
  >
    <Avatar
      :avatar="currentUser.avatar"
      size="small"
    />
    <span
      v-if="!slim"
      class="username"
    >
      {{ currentUser.username }}
    </span>
    <template slot="submenu">
      <NavItem
        :to="{ name: 'settings' }"
        :label="$t('nav.settings.index')"
        icon="fad fa-cog"
      />
      <NavItem divider />
      <NavItem
        :action="logout"
        menu-key="logout"
        :label="$t('nav.logout')"
        icon="fad fa-sign-out"
      />
    </template>
  </NavItem>
</template>

<script>
import NavItem from 'frontend/partials/Navigation/NavItem'
import Avatar from 'frontend/components/Avatar'
import NavigationMixin from 'frontend/mixins/Navigation'

export default {
  components: {
    NavItem,
    Avatar,
  },

  mixins: [
    NavigationMixin,
  ],

  computed: {
    active() {
      return [
        'settings-profile', 'settings-account', 'settings-hangar', 'settings-change-password',
      ].includes(this.$route.name)
    },
  },

  methods: {
    async logout() {
      await this.$store.dispatch('session/logout')
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
