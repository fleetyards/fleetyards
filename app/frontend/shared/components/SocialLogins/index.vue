<script lang="ts">
export default {
  name: "SocialLogins",
};
</script>

<script lang="ts" setup>
import OauthBtn from "@/shared/components/OauthBtn/index.vue";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useSessionStore } from "@/frontend/stores/session";
import { OauthBtnProvidersEnum } from "@/shared/components/OauthBtn/types";

type Props = {
  block?: boolean;
  onlyIcons?: boolean;
};

withDefaults(defineProps<Props>(), {
  block: true,
  onlyIcons: false,
});

const sessionStore = useSessionStore();

const { isFeatureEnabled } = useFeatures();

const providerActive = (provider: OauthBtnProvidersEnum) => {
  return isFeatureEnabled(`oauth-${provider}`);
};

const connections = computed(() => {
  return sessionStore.currentUser?.authConnections || [];
});

const activeProviders = computed(() => {
  return Object.values(OauthBtnProvidersEnum).filter(providerActive);
});
</script>

<template>
  <div class="social-logins" :class="{ block: block, 'only-icons': onlyIcons }">
    <OauthBtn
      v-for="provider in activeProviders"
      :key="provider"
      :provider="provider"
      :connected="connections.includes(provider)"
      :only-icon="onlyIcons"
      inline
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
