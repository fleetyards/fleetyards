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
    <template #submenu>
      <NavItem
        :to="{ name: 'settings' }"
        :active="active"
        :label="t('nav.settings.index')"
        icon="fal fa-cog"
      />
      <NavItem :divider="true" />
      <template v-if="currentUser.rsiHandle">
        <NavItem
          :href="`https://robertsspaceindustries.com/citizens/${currentUser.rsiHandle}`"
          :label="t('nav.rsiProfile')"
          :image="require('@/images/rsi_logo.png')"
        />
        <NavItem :divider="true" />
      </template>
      <NavItem
        :action="logout"
        menu-key="logout"
        :label="t('nav.logout')"
        icon="fal fa-sign-out"
      />
    </template>
  </NavItem>
</template>

<script lang="ts" setup>
import sessionCollection from "@/frontend/api/collections/Session";
import NavItem from "../NavItem/index.vue";
import { useRoute } from "vue-router";
import { useI18n } from "@/frontend/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";

const sessionStore = useSessionStore();

const { currentUser } = storeToRefs(sessionStore);

const { t } = useI18n();

const route = useRoute();

const active = computed(() => {
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
  ].includes(String(route.name));
});

const logout = async () => {
  await sessionCollection.destroy();

  sessionStore.logout();
};
</script>

<script lang="ts">
export default {
  name: "UserNav",
};
</script>

<style lang="scss">
@import "index";
</style>
