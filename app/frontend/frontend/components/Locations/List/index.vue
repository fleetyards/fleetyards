<script lang="ts">
export default {
  name: "LocationsList",
};
</script>

<script lang="ts" setup>
import LocationRow from "@/frontend/components/Locations/Row/index.vue";
import RowList from "@/shared/components/RowList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Location } from "@/services/fyApi";

type Props = {
  locations: Location[];
  emptyVisible?: boolean;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <RowList
    :records="locations"
    :empty-visible="emptyVisible"
    :empty-name="t('labels.filters.locations.name')"
  >
    <template #default="{ record }">
      <LocationRow :location="record" />
    </template>
  </RowList>
</template>
