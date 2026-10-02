<script lang="ts">
export default {
  name: "FleetDirectoryList",
};
</script>

<script lang="ts" setup>
import FleetDirectoryRow from "@/frontend/components/Fleets/Directory/Row/index.vue";
import RowList from "@/shared/components/RowList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type FleetDirectoryEntry } from "@/services/fyApi";

type Props = {
  fleets: FleetDirectoryEntry[];
  emptyVisible?: boolean;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <RowList
    :records="fleets"
    :empty-visible="emptyVisible"
    :empty-name="t('labels.fleetDirectory.name')"
  >
    <template #default="{ record }">
      <FleetDirectoryRow :fleet="record" />
    </template>
  </RowList>
</template>
