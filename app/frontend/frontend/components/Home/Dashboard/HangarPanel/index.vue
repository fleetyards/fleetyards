<script lang="ts">
export default {
  name: "HomeDashboardHangarPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import DashboardEmpty from "@/shared/components/Dashboard/Empty/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useHangarStats, useSyncRsiHangarLastRead } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t, l } = useI18n();

const {
  data: stats,
  isLoading,
  isFetching,
  isLoadingError,
} = useHangarStats(undefined, { query: liveQuery });

const { data: lastRead } = useSyncRsiHangarLastRead({
  query: { retry: false },
});

const empty = computed(
  () => !!stats.value && !stats.value.total && !stats.value.wishlistTotal,
);
</script>

<template>
  <DashboardPanel
    :title="t('home.dashboard.hangar.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!stats || empty"
    :more="{ name: 'hangar' }"
    :more-label="t('home.dashboard.hangar.open')"
    data-test="home-hangar"
  >
    <div v-if="stats" class="metrics-card__rows">
      <div class="metrics-card__row">
        <div class="metrics-card__row__label">
          {{ t("home.dashboard.hangar.ships") }}
        </div>
        <div class="metrics-card__row__value">{{ stats.total }}</div>
      </div>
      <div class="metrics-card__row">
        <div class="metrics-card__row__label">
          {{ t("home.dashboard.hangar.wishlist") }}
        </div>
        <div class="metrics-card__row__value">{{ stats.wishlistTotal }}</div>
      </div>
      <div v-if="lastRead?.finishedAt" class="metrics-card__row">
        <div class="metrics-card__row__label">
          {{ t("home.dashboard.hangar.synced") }}
        </div>
        <div class="metrics-card__row__value">
          {{ l(lastRead.finishedAt, "datetime.formats.short") }}
        </div>
      </div>
    </div>
    <template #empty>
      <DashboardEmpty
        icon="fa-warehouse"
        :title="t('home.dashboard.hangar.empty.title')"
        :hint="t('home.dashboard.hangar.empty.hint')"
      >
        <Btn :size="BtnSizesEnum.SM" :to="{ name: 'hangar' }">
          {{ t("home.dashboard.hangar.empty.action") }}
        </Btn>
      </DashboardEmpty>
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";
</style>
