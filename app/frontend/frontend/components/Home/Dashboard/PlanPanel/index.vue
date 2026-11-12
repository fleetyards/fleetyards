<script lang="ts">
export default {
  name: "HomeDashboardPlanPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useHangarPlans } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t, l } = useI18n();

const { data, isLoading, isFetching, isLoadingError } = useHangarPlans({
  query: liveQuery,
});

const plans = computed(() =>
  [...(data.value || [])].sort((a, b) =>
    b.updatedAt.localeCompare(a.updatedAt),
  ),
);

// The plan the pilot touched last is the one they are working on.
const plan = computed(() => plans.value[0]);
</script>

<template>
  <DashboardPanel
    :title="t('home.dashboard.plan.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!plan"
    :more="plan ? { name: 'hangar-plans' } : undefined"
    :more-label="t('home.dashboard.plan.all')"
    data-test="home-plan"
  >
    <router-link
      v-if="plan"
      :to="{ name: 'hangar-plan', params: { id: plan.id } }"
      class="home-plan"
    >
      <span class="home-plan__name">{{ plan.name }}</span>
      <span class="home-plan__sub">
        <span>{{
          t("home.dashboard.plan.steps", { count: plan.slotsCount })
        }}</span>
        <span>{{
          t("home.dashboard.plan.updated", {
            date: l(plan.updatedAt, "datetime.formats.short"),
          })
        }}</span>
      </span>
    </router-link>
    <p v-if="plans.length > 1" class="home-plan__more">
      {{ t("home.dashboard.plan.more", { count: plans.length - 1 }) }}
    </p>
    <template #empty>
      <div class="home-plan__pitch" data-test="home-plan-pitch">
        <p>{{ t("home.dashboard.plan.empty.hint") }}</p>
        <Btn :size="BtnSizesEnum.SM" :to="{ name: 'hangar-plans' }">
          <i class="fa-light fa-route" aria-hidden="true" />
          {{ t("home.dashboard.plan.empty.action") }}
        </Btn>
      </div>
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.home-plan {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 10px 12px;
  border: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
  border-radius: 10px;
  background: var(--color-gray-black, #1a1d21);
  color: inherit;
  text-decoration: none;

  &:hover {
    border-color: var(--color-edge, rgb(122 130 136 / 0.5));
  }
}

.home-plan__name {
  color: var(--color-lifted, #eee);
  font-weight: 600;
}

.home-plan__sub {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 10px;
  color: var(--color-text-dim, #959595);
  font-size: 0.75rem;
}

.home-plan__more {
  margin: 10px 0 0;
  color: var(--color-text-dim, #959595);
  font-size: 0.8125rem;
}

.home-plan__pitch {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 12px;

  p {
    margin: 0;
  }
}
</style>
