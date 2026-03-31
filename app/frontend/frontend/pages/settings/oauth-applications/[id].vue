<script lang="ts">
export default {
  name: "SettingsOauthApplicationParent",
};
</script>

<script lang="ts" setup>
import { useOauthApplication } from "@/services/fyApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: oauthApplication, ...asyncStatus } = useOauthApplication(
  route.params.id as string,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :oauth-application="oauthApplication" />
    </template>
  </AsyncData>
</template>
