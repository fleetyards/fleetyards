<script lang="ts">
export default {
  name: "AdminAnnouncementLayout",
};
</script>

<script lang="ts" setup>
import { useAnnouncement as useAnnouncementQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

// A getter rather than the string: the route param is what the query is keyed
// on, and this layout is reused when only the id changes.
const id = computed(() => route.params.id as string);

const { data: announcement, ...asyncStatus } = useAnnouncementQuery(id);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <!-- Keyed so the edit form re-reads its initial values when the route
           moves to another announcement rather than keeping the first one's. -->
      <router-view :key="id" :announcement="announcement" />
    </template>
  </AsyncData>
</template>
