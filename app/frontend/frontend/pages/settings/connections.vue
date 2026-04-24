<script lang="ts">
export default {
  name: "SettingsConnections",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import SocialLogins from "@/shared/components/SocialLogins/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";

const sessionStore = useSessionStore();
void sessionStore.refreshUser();

const { t } = useI18n();
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'settings' }, label: t('nav.settings.index') }]"
  />

  <Heading hero>{{ t("headlines.settings.connections") }}</Heading>

  <div v-if="sessionStore.currentUser" class="row">
    <div class="col-12">
      <SocialLogins :block="false" disconnectable />
    </div>
  </div>
</template>
