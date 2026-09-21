<script lang="ts">
export default {
  name: "AdminAnnouncementLayout",
};
</script>

<script lang="ts" setup>
import { useAnnouncement as useAnnouncementQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useAnnouncementUpdates } from "@/admin/composables/useAnnouncementUpdates";

const route = useRoute();

// A getter rather than the string: the route param is what the query is keyed
// on, and this layout is reused when only the id changes.
const id = computed(() => route.params.id as string);

const { data: announcement, ...asyncStatus } = useAnnouncementQuery(id);

// Here as well as on the list: an admin who publishes and then opens the
// announcement is watching the same four deliveries settle, from the same
// broadcast. The handler patches whichever of the two queries it finds.
useAnnouncementUpdates();
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
