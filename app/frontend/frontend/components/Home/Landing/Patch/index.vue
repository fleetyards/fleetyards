<script lang="ts">
export default {
  name: "HomeLandingPatch",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import HomePatchPanel from "@/frontend/components/Home/PatchPanel/index.vue";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import { usePatchChanges, useStats } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const { data: stats } = useStats();

const {
  data: patchChanges,
  isLoading,
  isFetching,
  isLoadingError,
} = usePatchChanges();

const mostChanged = computed(() => (patchChanges.value || []).slice(0, 5));

const facts = computed(() => [
  {
    key: "changed",
    label: t("home.patch.shipsChanged"),
    value: stats.value?.patchChangedShipsCount,
  },
]);
</script>

<template>
  <section data-test="home-landing-patch">
    <Heading :level="HeadingLevelEnum.H2">
      {{ t("home.landing.patch.title") }}
    </Heading>
    <p class="home-landing-patch__subline">
      {{ t("home.landing.patch.subline") }}
    </p>
    <div class="home-landing-patch">
      <HomePatchPanel :facts="facts" />
      <DashboardPanel
        :title="t('home.landing.patch.mostChanged')"
        :pending="isLoading"
        :fetching="isFetching"
        :failed="isLoadingError"
        :empty="!mostChanged.length"
        :more="{ name: 'stats' }"
      >
        <div class="home-landing-patch__rows">
          <RowListItem
            v-for="entry in mostChanged"
            :key="entry.label"
            :badges="[
              {
                key: 'changes',
                label: t('home.landing.patch.changes'),
                value: String(entry.count),
              },
            ]"
          >
            <template #name>{{ entry.label }}</template>
          </RowListItem>
        </div>
      </DashboardPanel>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.home-landing-patch {
  display: grid;
  grid-template-columns: minmax(0, 1.4fr) minmax(0, 1fr);
  gap: 16px;
  align-items: start;
}

.home-landing-patch__subline {
  margin: 0 0 12px;
  color: var(--color-text-dim, #959595);
}

.home-landing-patch__rows {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

@media (max-width: 991px) {
  .home-landing-patch {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
