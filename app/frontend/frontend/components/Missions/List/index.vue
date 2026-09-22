<script lang="ts">
export default {
  name: "MissionsList",
};
</script>

<script lang="ts" setup>
import MissionRow from "@/frontend/components/Missions/Row/index.vue";
import RowList from "@/shared/components/RowList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type GameMission } from "@/services/fyApi";

type Props = {
  missions: GameMission[];
  emptyVisible?: boolean;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <RowList
    :records="missions"
    :empty-visible="emptyVisible"
    :empty-name="t('labels.filters.missions.name')"
  >
    <template #default="{ record }">
      <MissionRow :mission="record" />
    </template>
  </RowList>
</template>
