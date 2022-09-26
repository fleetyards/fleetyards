<template>
  <NavItem
    v-if="currentUser"
    :submenu-active="active"
    submenu-direction="up"
    menu-key="user-menu"
    :image="currentUser.avatar"
    :avatar="true"
    :label="currentUser.username"
    class="user-menu"
  >
    <template slot="submenu">
      <NavItem
        :to="{ name: 'settings' }"
        :active="active"
        :label="$t('nav.settings.index')"
        icon="fal fa-cog"
      />
      <NavItem :divider="true" />
      <template v-if="currentUser.rsiHandle">
        <NavItem
          :href="`https://robertsspaceindustries.com/citizens/${currentUser.rsiHandle}`"
          :label="$t('nav.rsiProfile')"
          :image="require('@/images/rsi_logo.png')"
        />
        <NavItem :divider="true" />
      </template>
      <NavItem
        :action="logout"
        menu-key="logout"
        :label="$t('nav.logout')"
        icon="fal fa-sign-out"
      />
    </template>
  </NavItem>
</template>

<script>
import NavItem from "@/frontend/core/components/Navigation/NavItem/index.vue";
import NavigationMixin from "@/frontend/mixins/Navigation";
import sessionCollection from "@/frontend/api/collections/Session";

export default {
  name: "UserNav",

  components: {
    NavItem,
  },

  mixins: [NavigationMixin],

  computed: {
    active() {
      return [
        "settings-profile",
        "settings-account",
        "settings-hangar",
        "settings-notifications",
        "settings-security-status",
        "settings-two-factor-enable",
        "settings-two-factor-disable",
        "settings-two-factor-backup-codes",
        "settings-change-password",
      ].includes(this.$route.name);
    },
  },

  methods: {
    async logout() {
      await sessionCollection.destroy();
      await this.$store.dispatch("session/logout");
    },
  },
};
</script>

<style lang="scss">
@import "index";
</style>
