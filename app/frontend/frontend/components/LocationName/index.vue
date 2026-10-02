<script lang="ts">
export default {
  name: "LocationName",
};
</script>

<script lang="ts" setup>
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";

type Props = {
  // The text the record keeps.
  text?: string | null;
  // The place it is linked to, where it names one of ours.
  linked?: { slug: string; name?: string | null } | null;
};

defineProps<Props>();
</script>

<!-- A place a record names: a link to its page where it is one of ours, its
     text where it is not. -->
<template>
  <!-- With the hover card every catalogue link has. -->
  <span v-if="linked" class="location-name" data-test="location-name">
    <CatalogueItemPopover
      :item="{ type: 'Location', slug: linked.slug, name: text || linked.name }"
    />
  </span>
  <span v-else-if="text" class="location-name">{{ text }}</span>
</template>
