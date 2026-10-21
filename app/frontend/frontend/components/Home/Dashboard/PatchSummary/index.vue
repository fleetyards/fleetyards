<script lang="ts">
export default {
  name: "HomeDashboardPatchSummary",
};
</script>

<script lang="ts" setup>
import HomePatchPanel from "@/frontend/components/Home/PatchPanel/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useMyPatchChanges, useStats } from "@/services/fyApi";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const { data: stats } = useStats();

const { data: mine } = useMyPatchChanges({ query: liveQuery });

const facts = computed(() => [
  {
    key: "changed",
    label: t("home.patch.shipsChanged"),
    value: stats.value?.patchChangedShipsCount,
  },
  {
    key: "mine",
    label: t("home.patch.inYourHangar"),
    value: mine.value?.totalCount,
  },
]);

const lede = computed(() =>
  mine.value?.totalCount
    ? t("home.patch.yoursChanged", { count: mine.value.totalCount })
    : undefined,
);
</script>

<template>
  <HomePatchPanel :facts="facts" :lede="lede">
    <Btn :size="BtnSizesEnum.SM" :to="{ name: 'stats' }">
      <i class="fa-light fa-code-compare" />
      {{ t("home.patch.whatChanged") }}
    </Btn>
  </HomePatchPanel>
</template>
