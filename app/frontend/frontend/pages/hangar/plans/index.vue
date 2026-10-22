<script lang="ts">
export default {
  name: "HangarPlansPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import PageActions from "@/shared/components/PageActions/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useHangarPlans } from "@/services/fyApi";

const { t, l } = useI18n();
const comlink = useComlink();

const { data: plans, isLoading } = useHangarPlans();

const openCreate = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/Planner/PlanModal/index.vue"),
  });
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'hangar' }, label: t('nav.hangar.index') }]"
  />
  <Heading size="hero" hero>{{ t("hangarPlanner.title") }}</Heading>
  <p class="plans-lead">{{ t("hangarPlanner.lead") }}</p>

  <PageActions>
    <Btn data-test="hangar-plan-create" @click="openCreate">
      <i class="fa-light fa-plus" />
      {{ t("hangarPlanner.createPlan") }}
    </Btn>
  </PageActions>

  <Loader :loading="isLoading" />

  <div v-if="plans?.length" class="plans-grid">
    <Panel
      v-for="plan in plans"
      :key="plan.id"
      :variant="PanelVariantsEnum.SLIM"
      data-test="hangar-plan-card"
    >
      <PanelHeading compact divider>
        <router-link :to="{ name: 'hangar-plan', params: { id: plan.id } }">
          {{ plan.name }}
        </router-link>
        <template #subtitle>
          {{ t("hangarPlanner.slotsCount", { count: plan.slotsCount }) }}
          <Pill v-if="plan.shared" variant="neutral">
            {{ t("hangarPlanner.shared") }}
          </Pill>
        </template>
      </PanelHeading>
      <PanelBody>
        <p v-if="plan.description" class="plans-description">
          {{ plan.description }}
        </p>
        <small class="plans-meta">
          {{
            t("hangarPlanner.updatedAt", {
              date: l(plan.updatedAt, "datetime.formats.date"),
            })
          }}
        </small>
      </PanelBody>
    </Panel>
  </div>

  <Empty v-else-if="!isLoading" variant="box" hide-actions>
    <template #headline>{{ t("hangarPlanner.empty.title") }}</template>
    <template #info>
      <p>{{ t("hangarPlanner.empty.text") }}</p>
    </template>
  </Empty>
</template>

<style lang="scss" scoped>
.plans-lead {
  max-width: 720px;
  color: var(--color-text-dim);
}

.plans-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
}

.plans-description {
  margin: 0 0 8px;
}

.plans-meta {
  color: var(--color-text-dim);
}
</style>
