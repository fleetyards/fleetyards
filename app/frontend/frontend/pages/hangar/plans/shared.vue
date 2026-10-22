<script lang="ts">
export default {
  name: "HangarPlanSharedPage",
};
</script>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import Heading from "@/shared/components/base/Heading/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import SlotCard from "@/frontend/components/Hangar/Planner/SlotCard/index.vue";
import SummaryPanel from "@/frontend/components/Hangar/Planner/SummaryPanel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  usePublicHangarPlan,
  usePublicHangarPlanSummary,
} from "@/services/fyApi";

const route = useRoute();
const { t } = useI18n();

const token = computed(() => String(route.params.token));

const { data: plan, isLoading, isError } = usePublicHangarPlan(token);
const { data: summary } = usePublicHangarPlanSummary(token);

const slotCost = (slotId: string) =>
  summary.value?.slots.find((cost) => cost.slotId === slotId);
</script>

<template>
  <Loader :loading="isLoading" />

  <Alert v-if="isError" variant="neutral">
    {{ t("hangarPlanner.sharedMissing") }}
  </Alert>

  <template v-if="plan">
    <Heading size="hero" hero>{{ plan.name }}</Heading>
    <p v-if="plan.description" class="plan-description">
      {{ plan.description }}
    </p>

    <div class="plan-layout">
      <section class="plan-slots">
        <SlotCard
          v-for="slot in plan.slots"
          :key="slot.id"
          :plan-id="plan.id"
          :slot="slot"
          :cost="slotCost(slot.id)"
          readonly
        />
      </section>
      <aside>
        <SummaryPanel :summary="summary" />
      </aside>
    </div>
  </template>
</template>

<style lang="scss" scoped>
.plan-description {
  color: var(--color-text-dim);
}

.plan-layout {
  display: grid;
  grid-template-columns: minmax(0, 2fr) minmax(280px, 1fr);
  gap: 16px;

  @media (max-width: 991px) {
    grid-template-columns: minmax(0, 1fr);
  }
}

.plan-slots {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
</style>
