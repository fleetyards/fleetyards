<script lang="ts">
export default {
  name: "PublicHangarPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import { usePublicUser as usePublicUserQuery } from "@/services/fyApi";

const route = useRoute();

const username = computed(() => route.params.username as string);

const { data: user, refetch, ...asyncStatus } = usePublicUserQuery(username);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :user="user" />
    </template>
  </AsyncData>
</template>
