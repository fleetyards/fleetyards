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
    <UserNav v-if="isAuthenticated" />
    <NavItem
      v-else
      key="user-menu-guest"
      :to="{ name: 'login' }"
      :label="t('nav.login')"
      icon="fal fa-sign-in"
    />
  </ul>
</template>

<script lang="ts" setup>
import NavItem from "../NavItem/index.vue";
import UserNav from "../UserNav/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useI18n } from "@/shared/composables/useI18n";
import { useNavStore } from "@/frontend/stores/nav";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";

const { t } = useI18n();

const mobile = useMobile();

const navStore = useNavStore();

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

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
</script>

<script lang="ts">
export default {
  name: "NavFooter",
};
</script>
