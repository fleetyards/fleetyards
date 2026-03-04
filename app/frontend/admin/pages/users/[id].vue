<script lang="ts" setup>
import { useUser as useUserQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: user, ...asyncStatus } = useUserQuery(route.params.id as string);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :user="user" />
    </template>
  </AsyncData>
</template>
