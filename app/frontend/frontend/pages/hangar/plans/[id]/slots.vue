<script lang="ts">
export default {
  name: "HangarPlanSlotsPage",
};
</script>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import PageActions from "@/shared/components/PageActions/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import SlotCard from "@/frontend/components/Hangar/Planner/SlotCard/index.vue";
import SlotPlaceholders from "@/frontend/components/Hangar/Planner/SlotPlaceholders/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useHangarPlan, useHangarPlanSummary } from "@/services/fyApi";

const route = useRoute();
const { t } = useI18n();
const comlink = useComlink();

const planId = computed(() => String(route.params.id));

const { data: plan, isLoading } = useHangarPlan(planId);
const { data: summary } = useHangarPlanSummary(planId);

const slotCost = (slotId: string) =>
  summary.value?.slots.find((cost) => cost.slotId === slotId);

const addSlot = (label?: string) =>
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/Planner/SlotModal/index.vue"),
    props: { planId: planId.value, label },
  });
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      { to: { name: 'hangar' }, label: t('nav.hangar.index') },
      { to: { name: 'hangar-plans' }, label: t('nav.hangar.plans') },
      {
        to: { name: 'hangar-plan', params: { id: planId } },
        label: plan?.name ?? '',
      },
    ]"
  />
  <Loader :loading="isLoading" />

  <template v-if="plan">
    <Heading size="hero" hero>{{ t("hangarPlanner.slotsTitle") }}</Heading>

    <PageActions>
      <Btn data-test="hangar-plan-add-slot" @click="addSlot()">
        <i class="fa-light fa-plus" />
        {{ t("hangarPlanner.addSlot") }}
      </Btn>
    </PageActions>

    <section class="plan-slots">
      <SlotPlaceholders v-if="!plan.slots.length" @add="addSlot" />
      <SlotCard
        v-for="slot in plan.slots"
        :key="slot.id"
        :plan-id="plan.id"
        :slot="slot"
        :cost="slotCost(slot.id)"
      />
    </section>
  </template>
</template>

<style lang="scss" scoped>
.plan-slots {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
</style>
