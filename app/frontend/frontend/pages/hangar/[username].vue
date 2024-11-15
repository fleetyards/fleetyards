<script lang="ts">
export default {
  name: "PublicHangarPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import { usePublicUserQueries } from "@/frontend/composables/usePublicUserQueries";

const route = useRoute();

const username = computed(() => route.params.username as string);

const { publicUserQuery } = usePublicUserQueries();

const {
  data: user,
  refetch,
  ...asyncStatus
} = publicUserQuery({ username: username.value });
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :user="user" />
    </template>
  </AsyncData>
</template>
