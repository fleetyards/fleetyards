<script lang="ts">
export default {
  name: "ModelsAddToHangarNotificationAccountRequired",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import MessageBody from "@/shared/components/AppNotifications/Message/Body/index.vue";

const { t } = useI18n();
</script>

<template>
  <MessageBody>
    {{ t("messages.error.hangar.accountRequired.paragraph1") }}
    <router-link :to="{ name: 'signup' }">
      {{ t("actions.signUp") }}
    </router-link>
    {{ t("labels.or") }}
    <router-link :to="{ name: 'login' }"> {{ t("actions.login") }}</router-link>
    {{ t("messages.error.hangar.accountRequired.paragraph2") }}
    <br />
    {{ t("messages.error.hangar.accountRequired.paragraph3") }}
    <router-link :to="{ name: 'hangar-preview' }">
      {{ t("actions.here") }}</router-link
    >.
  </MessageBody>
</template>
