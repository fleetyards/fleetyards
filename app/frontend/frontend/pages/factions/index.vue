<script lang="ts">
export default {
  name: "FactionsPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import RowList from "@/shared/components/RowList/index.vue";
import FactionRow from "@/frontend/components/Factions/Row/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFactions } from "@/services/fyApi";

const { t } = useI18n();

const { data: factions, ...asyncStatus } = useFactions();
</script>

<template>
  <Heading hidden>{{ t("headlines.factions.index") }}</Heading>

  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <RowList
        :records="factions || []"
        :empty-visible="!factions?.length"
        :empty-name="t('labels.faction.name')"
      >
        <template #default="{ record }">
          <FactionRow :faction="record" />
        </template>
      </RowList>
    </template>
  </AsyncData>
</template>
