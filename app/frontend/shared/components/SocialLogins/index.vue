<script lang="ts">
export default {
  name: "SocialLogins",
};
</script>

<script lang="ts" setup>
import OauthBtn from "@/shared/components/OauthBtn/index.vue";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useSessionStore } from "@/frontend/stores/session";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import { OauthBtnProvidersEnum } from "@/shared/components/OauthBtn/types";
import { useDisconnectOauthProvider as useDisconnectOauthProviderMutation } from "@/services/fyApi";

type Props = {
  block?: boolean;
  onlyIcons?: boolean;
  disconnectable?: boolean;
  primaryProviders?: `${OauthBtnProvidersEnum}`[];
};

const props = withDefaults(defineProps<Props>(), {
  block: true,
  onlyIcons: false,
  disconnectable: false,
  primaryProviders: () => [],
});

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const sessionStore = useSessionStore();

const { isFeatureEnabled } = useFeatures();

const disconnectingProvider = ref<string | null>(null);

const providerActive = (provider: OauthBtnProvidersEnum) => {
  return isFeatureEnabled(`oauth-${provider}`);
};

const connections = computed(() => {
  return sessionStore.currentUser?.authConnections || [];
});

const activeProviders = computed(() => {
  const providers = Object.values(OauthBtnProvidersEnum).filter(providerActive);

  return providers.sort((a, b) => {
    const aPrimary = props.primaryProviders.includes(a);
    const bPrimary = props.primaryProviders.includes(b);
    if (aPrimary !== bPrimary) return aPrimary ? -1 : 1;

    if (props.disconnectable) {
      const aConnected = connections.value.includes(a);
      const bConnected = connections.value.includes(b);
      if (aConnected !== bConnected) return aConnected ? -1 : 1;
    }

    return 0;
  });
});

const disconnectMutation = useDisconnectOauthProviderMutation();

const handleDisconnect = async (provider: `${OauthBtnProvidersEnum}`) => {
  disconnectingProvider.value = provider;

  await disconnectMutation
    .mutateAsync({ provider })
    .then((user) => {
      sessionStore.currentUser = user;

      displaySuccess({
        text: t("messages.oauth.disconnect.success"),
      });
    })
    .catch((error) => {
      console.error(error);

      displayAlert({
        text: t("messages.oauth.disconnect.failure"),
      });
    })
    .finally(() => {
      disconnectingProvider.value = null;
    });
};

defineExpose({
  connections,
  activeProviders,
});
</script>

<template>
  <div
    v-if="activeProviders.length"
    class="social-logins"
    :class="{ block: block, 'only-icons': onlyIcons }"
  >
    <OauthBtn
      v-for="provider in activeProviders"
      :key="provider"
      :provider="provider"
      :block="primaryProviders.includes(provider)"
      :inline="!primaryProviders.includes(provider)"
      :connected="connections.includes(provider)"
      :disconnectable="disconnectable && connections.includes(provider)"
      :disconnecting="disconnectingProvider === provider"
      :only-icon="onlyIcons"
      @disconnect="handleDisconnect"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
