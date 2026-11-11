<script lang="ts">
export default {
  name: "HangarPlanSuggestionsPage",
};
</script>

<script lang="ts" setup>
import type { Component } from "vue";
import { useRoute, useRouter } from "vue-router";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import Loader from "@/shared/components/Loader/index.vue";
import ShipName from "@/frontend/components/Hangar/Planner/ShipName/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type HangarPlanFleetEntry,
  type HangarPlanRedundancy,
  HangarPlanRedundancyKindEnum,
  useHangarPlan,
  useHangarPlanSuggestions,
} from "@/services/fyApi";

const route = useRoute();
const { t } = useI18n();
const { money } = usePlanMoney();
const comlink = useComlink();

const planId = computed(() => String(route.params.id));

const { data: plan, isLoading } = useHangarPlan(planId);
const { data: suggestions, isLoading: suggestionsLoading } =
  useHangarPlanSuggestions(planId);

const redundancies = computed(() => suggestions.value?.redundancies ?? []);

const title = (redundancy: HangarPlanRedundancy) =>
  redundancy.kind === HangarPlanRedundancyKindEnum.DUPLICATE
    ? t("hangarPlanner.suggestions.duplicate", {
        ship: redundancy.model?.name,
        count: redundancy.entries.length,
      })
    : [
        redundancy.focusLabel,
        redundancy.sizeLabel,
        redundancy.classificationLabel,
      ]
        .filter(Boolean)
        .join(" · ");

const hint = (redundancy: HangarPlanRedundancy) =>
  t(`hangarPlanner.suggestions.hints.${redundancy.kind}`, {
    count: redundancy.entries.length,
  });

// Where a ship of the planned hangar comes from: a slot's unit, possibly
// filled by a hangar ship, or a hangar ship the plan leaves alone.
const origin = (entry: HangarPlanFleetEntry) =>
  [
    entry.slotLabel
      ? t("hangarPlanner.suggestions.inSlot", { slot: entry.slotLabel })
      : t("hangarPlanner.suggestions.inHangar"),
    entry.vehicleName,
    entry.vehicleStatus
      ? t(`hangarPlanner.vehicleStatuses.${entry.vehicleStatus}`)
      : undefined,
  ]
    .filter(Boolean)
    .join(" · ");

const openModal = (
  component: () => Promise<Component>,
  props: Record<string, unknown>,
) =>
  comlink.emit("open-modal", {
    component,
    props: { planId: planId.value, ...props },
  });

const melt = (entry: HangarPlanFleetEntry) =>
  openModal(
    () => import("@/frontend/components/Hangar/Planner/MeltModal/index.vue"),
    { vehicleId: entry.vehicleId },
  );

const router = useRouter();

// The slot opens in the plan's ship panel, where its ships are chosen.
const openSlot = (entry: HangarPlanFleetEntry) => {
  if (!entry.slotId) return;

  void router.push({
    name: "hangar-plan",
    params: { id: planId.value },
    query: { slot: entry.slotId },
  });
};
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
  <Loader :loading="isLoading || suggestionsLoading" />

  <template v-if="plan && suggestions">
    <Heading size="hero" hero>
      {{ t("hangarPlanner.suggestions.title") }}
    </Heading>
    <p class="plan-suggestions__lead">
      {{ t("hangarPlanner.suggestions.lead") }}
    </p>

    <Panel :variant="PanelVariantsEnum.SLIM" data-test="hangar-plan-redundant">
      <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
        {{ t("hangarPlanner.suggestions.redundant") }}
      </PanelHeading>
      <PanelBody>
        <p v-if="!redundancies.length" class="plan-suggestions__muted">
          {{ t("hangarPlanner.suggestions.noRedundant") }}
        </p>
        <section
          v-for="(redundancy, index) in redundancies"
          :key="index"
          class="plan-suggestion"
          :data-test="`hangar-plan-redundancy-${redundancy.kind}`"
        >
          <h3 class="plan-suggestion__title">{{ title(redundancy) }}</h3>
          <p class="plan-suggestions__muted">{{ hint(redundancy) }}</p>
          <ul class="plan-suggestion__ships">
            <li
              v-for="(entry, entryIndex) in redundancy.entries"
              :key="entryIndex"
              class="plan-suggestion__ship"
              data-test="hangar-plan-redundant-ship"
            >
              <img
                :src="entry.model.image?.smallUrl || fallbackImage"
                alt=""
                class="plan-suggestion__image"
                loading="lazy"
              />
              <span class="plan-suggestion__text">
                <strong><ShipName :ship="entry.model" /></strong>
                <span class="plan-suggestions__muted">{{ origin(entry) }}</span>
              </span>
              <span class="plan-suggestion__price">
                {{ money(entry.model.pledgePrice) }}
              </span>
              <Btn
                v-if="entry.vehicleId && !entry.slotId"
                :size="BtnSizesEnum.XS"
                data-test="hangar-plan-redundant-melt"
                @click="melt(entry)"
              >
                <i class="fa-light fa-fire" />
                {{ t("hangarPlanner.decisions.melt") }}
              </Btn>
              <Btn
                v-if="entry.slotId"
                :size="BtnSizesEnum.XS"
                data-test="hangar-plan-redundant-slot"
                @click="openSlot(entry)"
              >
                <i class="fa-light fa-pen" />
                {{ t("hangarPlanner.editSlot") }}
              </Btn>
            </li>
          </ul>
        </section>
      </PanelBody>
    </Panel>
  </template>
</template>

<style lang="scss" scoped>
.plan-suggestions__lead,
.plan-suggestions__muted {
  color: var(--color-text-dim);
}

.plan-suggestions__muted {
  margin: 0;
  font-size: 0.85rem;
}

.plan-suggestion {
  padding: 12px 0;

  & + & {
    border-top: 1px solid var(--color-edge-faint);
  }
}

.plan-suggestion__title {
  margin: 0 0 2px;
  font-size: 1rem;
  color: var(--color-lifted);
}

.plan-suggestion__ships {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 10px 0 0;
  padding: 0;
  list-style: none;
}

.plan-suggestion__ship {
  display: flex;
  gap: 12px;
  align-items: center;
  padding: 8px 12px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
  background: var(--color-control);
}

.plan-suggestion__image {
  flex: none;
  width: 72px;
  height: 42px;
  object-fit: cover;
  border-radius: 6px;
}

.plan-suggestion__text {
  display: flex;
  flex: 1;
  flex-direction: column;
  min-width: 0;

  strong {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    color: var(--color-lifted);
  }
}

.plan-suggestion__price {
  font-weight: 600;
  white-space: nowrap;
  color: var(--color-lifted);
}
</style>
