<script lang="ts">
export default {
  name: "NavFooter",
};
</script>

<script lang="ts" setup>
import NavItem from "../NavItem/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useI18n } from "@/shared/composables/useI18n";
import { useNavStore } from "@/frontend/stores/nav";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";
import rsiLogo from "@/images/rsi_logo.png";
import { useApiClient } from "@/frontend/composables/useApiClient";

const { t } = useI18n();

const mobile = useMobile();

const navStore = useNavStore();

const sessionStore = useSessionStore();

const { isAuthenticated, currentUser } = storeToRefs(sessionStore);

const slim = computed(() => {
  return navStore.slim && !mobile.value;
});

const toggleSlimLabel = computed(() => {
  if (slim.value) {
    return t("nav.toggleSlimExpand");
  }

  return t("nav.toggleSlimCollapse");
});

const toggleSlim = () => {
  navStore.toggleSlim();
};

const { sessions: sessionsService } = useApiClient();

const logout = async () => {
  await sessionsService.deleteSession();

  sessionStore.logout();
};

const route = useRoute();

const settingsActive = computed(() => {
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
</script>

<template>
  <ul class="nav-bottom">
    <NavItem
      v-if="!mobile"
      :action="toggleSlim"
      :label="toggleSlimLabel"
      :icon="
        slim ? 'fal fa-chevron-double-right' : 'fal fa-chevron-double-left'
      "
    />
    <template v-if="isAuthenticated && currentUser">
      <NavItem
        :to="{ name: 'settings' }"
        :active="settingsActive"
        :label="t('nav.settings.index')"
        icon="fal fa-cog"
      />
      <template v-if="currentUser.rsiHandle">
        <NavItem
          :href="`https://robertsspaceindustries.com/citizens/${currentUser.rsiHandle}`"
          :label="t('nav.rsiProfile')"
          :image="rsiLogo"
        />
      </template>
      <NavItem
        :action="logout"
        menu-key="logout"
        :label="t('nav.logout')"
        icon="fal fa-sign-out"
      />
      <NavItem
        menu-key="user-menu"
        :image="currentUser.avatar"
        :avatar="true"
        :label="currentUser.username"
        class="user-menu"
      />
    </template>
    <NavItem
      v-else
      key="user-menu-guest"
      :to="{ name: 'login' }"
      :label="t('nav.login')"
      icon="fal fa-sign-in"
    />
  </ul>
</template>

<style lang="scss">
@import "index";
</style>
