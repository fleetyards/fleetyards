<script lang="ts">
export default {
  name: "ComponentPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import { useComponent as useComponentQuery } from "@/services/fyApi";

const route = useRoute();

const slug = computed(() => route.params.slug as string);

// Resolved once for the whole detail section: the overview and the history tab
// are siblings rather than one page, and each asking for the component itself
// would fetch it again on every switch between them.
const { data: component, ...asyncStatus } = useComponentQuery(slug);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :component="component" />
    </template>
  </AsyncData>
</template>
