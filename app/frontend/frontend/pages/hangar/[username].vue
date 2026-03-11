<script lang="ts">
export default {
  name: "PublicHangarPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import { usePublicUser as usePublicUserQuery } from "@/services/fyApi";
import { usePublicHangarMeta } from "@/frontend/composables/usePublicHangarMeta";

const route = useRoute();

const username = computed(() => route.params.username as string);

const { data: user, ...asyncStatus } = usePublicUserQuery(username);

usePublicHangarMeta(user);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :user="user" />
    </template>
  </AsyncData>
</template>
