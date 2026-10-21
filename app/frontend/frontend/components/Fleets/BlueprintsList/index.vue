<script lang="ts">
export default {
  name: "FleetBlueprintsList",
};
</script>

<script lang="ts" setup>
import BlueprintRow from "@/frontend/components/Blueprints/Row/index.vue";
import RowList from "@/shared/components/RowList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type FleetBlueprint,
  type FleetWantedBlueprint,
} from "@/services/fyApi";

type Props = {
  blueprints: (FleetBlueprint | FleetWantedBlueprint)[];
  emptyVisible?: boolean;
};

defineProps<Props>();

const { t } = useI18n();

const membersOf = (record: FleetBlueprint | FleetWantedBlueprint) =>
  "owners" in record
    ? { members: record.owners, memberCount: record.ownerCount }
    : { members: record.wanters, memberCount: record.wanterCount };
</script>

<template>
  <!-- The catalogue's own row, handed the owners or wanters as well. A second
       row component would be the same recipe rendered twice, and the two would
       drift the first time either list gained a field. -->
  <RowList
    :records="blueprints"
    :empty-visible="emptyVisible"
    :empty-name="t('labels.filters.blueprints.name')"
  >
    <template #default="{ record }">
      <BlueprintRow :blueprint="record.blueprint" v-bind="membersOf(record)" />
    </template>
  </RowList>
</template>
