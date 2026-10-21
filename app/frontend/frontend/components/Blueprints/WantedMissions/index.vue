<script lang="ts">
export default {
  name: "BlueprintWantedMissionsList",
};
</script>

<script lang="ts" setup>
import MissionRow from "@/frontend/components/Missions/Row/index.vue";
import RowList from "@/shared/components/RowList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type HangarBlueprintMission,
  type ModelExtended,
} from "@/services/fyApi";

type Props = {
  missions: HangarBlueprintMission[];
  emptyVisible?: boolean;
  ship?: ModelExtended;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<!-- The mission catalogue's own row, handed the wanted blueprints that put
     the mission on this list. -->
<template>
  <RowList
    :records="missions"
    :empty-visible="emptyVisible"
    :empty-name="t('labels.filters.missions.name')"
  >
    <template #default="{ record }">
      <MissionRow
        :mission="record.mission"
        :ship="ship"
        :wanted-blueprints="record.wantedBlueprints"
      />
    </template>
  </RowList>
</template>
