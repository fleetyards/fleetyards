<script lang="ts">
export default {
  name: "ComponentViewerPage",
};
</script>

<script lang="ts" setup>
import ItemHoloViewer from "@/frontend/components/ItemHoloViewer/index.vue";
import { type Component } from "@/services/fyApi";

type Props = {
  component: Component;
};

defineProps<Props>();
</script>

<template>
  <ItemHoloViewer
    :name="component.name"
    :media="component.media"
    :back-route="{ name: 'component', params: { slug: component.slug } }"
  />
</template>
