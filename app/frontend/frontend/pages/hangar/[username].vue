<script lang="ts">
export default {
  name: "PublicHangarPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import { usePublicUser as usePublicUserQuery } from "@/services/fyApi";
import { usePublicHangarMeta } from "@/frontend/composables/usePublicHangarMeta";
import { usePublicHangarShare } from "@/frontend/composables/usePublicHangarShare";

const route = useRoute();

const username = computed(() => route.params.username as string);

const { share } = usePublicHangarShare();

const { data: user, ...asyncStatus } = usePublicUserQuery(
  username,
  computed(() => ({ share: share.value })),
);

usePublicHangarMeta(user);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :user="user" />
    </template>
  </AsyncData>
</template>
