<script lang="ts" setup>
import { useAdminUser as useAdminUserQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: adminUser, ...asyncStatus } = useAdminUserQuery(
  route.params.id as string,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :admin-user="adminUser" />
    </template>
  </AsyncData>
</template>
