<script lang="ts" setup>
import { useAnnouncement as useAnnouncementQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: announcement, ...asyncStatus } = useAnnouncementQuery(
  route.params.id as string,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :announcement="announcement" />
    </template>
  </AsyncData>
</template>
