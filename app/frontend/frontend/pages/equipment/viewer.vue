<script lang="ts">
export default {
  name: "EquipmentViewerPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import ItemHoloViewer from "@/frontend/components/ItemHoloViewer/index.vue";
import { useEquipmentItem as useEquipmentItemQuery } from "@/services/fyApi";

const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: equipment, ...asyncStatus } = useEquipmentItemQuery(slug);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <ItemHoloViewer
        v-if="equipment"
        :name="equipment.name"
        :media="equipment.media"
        :back-route="{
          name: 'equipment-item',
          params: { slug: equipment.slug },
        }"
      />
    </template>
  </AsyncData>
</template>
