<script lang="ts">
export default {
  name: "HangarPlanPage",
};
</script>

<script lang="ts" setup>
import type { Component } from "vue";
import { useRoute, useRouter } from "vue-router";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import PageActions from "@/shared/components/PageActions/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import Loader from "@/shared/components/Loader/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import HangarFlow from "@/frontend/components/Hangar/Planner/HangarFlow/index.vue";
import ComparisonDetails from "@/frontend/components/Hangar/Planner/ComparisonDetails/index.vue";
import SummaryPanel from "@/frontend/components/Hangar/Planner/SummaryPanel/index.vue";
import MeltContents from "@/frontend/components/Hangar/Planner/MeltContents/index.vue";
import CostTiles from "@/frontend/components/Hangar/Planner/CostTiles/index.vue";
import Readiness from "@/frontend/components/Hangar/Planner/Readiness/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import DriftAlert from "@/frontend/components/Hangar/Planner/DriftAlert/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import { useHangarPlanDecisions } from "@/frontend/composables/useHangarPlanDecisions";
import copyText from "@/shared/utils/CopyText";
import {
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
  type HangarPlanMelt,
  type HangarPlanSlot,
  HangarPlanSlotStateEnum,
  HangarPlanVehicleStatusEnum,
  useAddHangarPlanToWishlist,
  useDestroyHangarPlan,
  useDestroyHangarPlanMelt,
  useHangarPlan,
  useHangarPlanComparison,
  useHangarPlanDrift,
  useHangarPlans,
  useHangarPlanSummary,
  useShareHangarPlan,
  useUnshareHangarPlan,
} from "@/services/fyApi";

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { money } = usePlanMoney();
const comlink = useComlink();
const { displayAlert, displaySuccess } = useAppNotifications();
const { updatePlan } = useHangarPlanCache();

const planId = computed(() => String(route.params.id));

const { data: plan, isLoading } = useHangarPlan(planId);
const { data: summary, isFetching: summaryFetching } =
  useHangarPlanSummary(planId);
const { data: drift } = useHangarPlanDrift(planId);
const { data: comparison, isFetching: comparisonFetching } =
  useHangarPlanComparison(planId);
const { data: plans } = useHangarPlans();

const otherPlans = computed(() =>
  (plans.value ?? []).filter((entry) => entry.id !== planId.value),
);

const slotsIn = (state: HangarPlanSlotStateEnum) =>
  (plan.value?.slots ?? []).filter((slot) => slot.state === state).length;

const countOf = (status: HangarPlanVehicleStatusEnum) =>
  (comparison.value?.vehicles ?? []).filter((entry) => entry.status === status)
    .length;

const tallies = computed(() =>
  [
    {
      key: "pending",
      variant: PillVariantsEnum.WARNING,
      value: countOf(HangarPlanVehicleStatusEnum.PENDING),
    },
    {
      key: "change",
      variant: PillVariantsEnum.WARNING,
      value: countOf(HangarPlanVehicleStatusEnum.CHANGE),
    },
    { key: "kept", value: countOf(HangarPlanVehicleStatusEnum.KEPT) },
    { key: "upgraded", value: countOf(HangarPlanVehicleStatusEnum.UPGRADED) },
    { key: "melted", value: countOf(HangarPlanVehicleStatusEnum.MELTED) },
    {
      key: "toAcquire",
      variant: PillVariantsEnum.WARNING,
      value: (comparison.value?.gaps ?? []).reduce(
        (sum, gap) => sum + gap.count,
        0,
      ),
    },
  ]
    .map((tally) => ({ variant: PillVariantsEnum.NEUTRAL, ...tally }))
    .filter((tally) => tally.value > 0),
);

const { deciding, decide, keep, pendingIds } = useHangarPlanDecisions(
  planId,
  plan,
  comparison,
);

const openModal = (
  component: () => Promise<Component>,
  props: Record<string, unknown> = {},
) => comlink.emit("open-modal", { component, props });

const editPlan = () =>
  openModal(
    () => import("@/frontend/components/Hangar/Planner/PlanModal/index.vue"),
    { plan: plan.value },
  );

const addSlot = (label?: string) =>
  openModal(
    () => import("@/frontend/components/Hangar/Planner/SlotModal/index.vue"),
    { planId: planId.value, label },
  );

const openRoute = (
  candidate: HangarPlanCandidate,
  acquisition?: HangarPlanAcquisition,
) =>
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/Planner/RouteModal/index.vue"),
    props: { planId: planId.value, candidate, acquisition },
    wide: true,
  });

const pickShips = (slot: HangarPlanSlot) =>
  openModal(
    () =>
      import("@/frontend/components/Hangar/Planner/CandidatePickerModal/index.vue"),
    { planId: planId.value, slot },
  );

const openMelt = (melt?: HangarPlanMelt) =>
  openModal(
    () => import("@/frontend/components/Hangar/Planner/MeltModal/index.vue"),
    { planId: planId.value, melt },
  );

const destroyMelt = useDestroyHangarPlanMelt();
const removeMelt = async (melt: HangarPlanMelt) => {
  try {
    updatePlan(
      await destroyMelt.mutateAsync({
        hangarPlanId: planId.value,
        id: melt.id,
      }),
    );
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  }
};

const shareUrl = computed(() => {
  if (!plan.value?.shareToken) return undefined;

  const target = router.resolve({
    name: "hangar-plan-shared",
    params: { token: plan.value.shareToken },
  });

  return `${window.location.origin}${target.href}`;
});

const share = useShareHangarPlan();
const unshare = useUnshareHangarPlan();

const onShare = async () => {
  try {
    updatePlan(await share.mutateAsync({ id: planId.value }));
    displaySuccess({ text: t("hangarPlanner.messages.sharingOn") });
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  }
};

// Copied straight from the click, with nothing awaited first: a browser only
// lets a page write the clipboard while the click that asked for it is fresh.
const onCopyShareLink = () => {
  if (!shareUrl.value) return;

  copyText(shareUrl.value).then(
    () => displaySuccess({ text: t("hangarPlanner.messages.shareCopied") }),
    () => displayAlert({ text: t("hangarPlanner.messages.copyFailed") }),
  );
};

const onUnshare = async () => {
  try {
    updatePlan(await unshare.mutateAsync({ id: planId.value }));
    displaySuccess({ text: t("hangarPlanner.messages.unshared") });
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  }
};

const addToWishlist = useAddHangarPlanToWishlist();
const onAddToWishlist = async () => {
  try {
    const result = await addToWishlist.mutateAsync({ id: planId.value });
    displaySuccess({
      text: t("hangarPlanner.messages.addedToWishlist", {
        count: result.added,
      }),
    });
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  }
};

const destroyPlan = useDestroyHangarPlan();
const onDestroy = async () => {
  try {
    await destroyPlan.mutateAsync({ id: planId.value });
    await router.push({ name: "hangar-plans" });
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  }
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      { to: { name: 'hangar' }, label: t('nav.hangar.index') },
      { to: { name: 'hangar-plans' }, label: t('nav.hangar.plans') },
    ]"
  />
  <Loader :loading="isLoading" />

  <template v-if="plan">
    <Heading size="hero" hero>{{ plan.name }}</Heading>
    <p v-if="plan.description" class="plan-description">
      {{ plan.description }}
    </p>
    <div class="plan-meta">
      <Pill :variant="PillVariantsEnum.NEUTRAL">
        {{ t("hangarPlanner.slotsCount", { count: plan.slots.length }) }}
      </Pill>
      <Pill
        v-if="slotsIn(HangarPlanSlotStateEnum.UNDECIDED)"
        :variant="PillVariantsEnum.WARNING"
      >
        {{
          t("hangarPlanner.meta.undecided", {
            count: slotsIn(HangarPlanSlotStateEnum.UNDECIDED),
          })
        }}
      </Pill>
      <Pill
        v-if="slotsIn(HangarPlanSlotStateEnum.OPEN)"
        :variant="PillVariantsEnum.NEUTRAL"
      >
        {{
          t("hangarPlanner.meta.open", {
            count: slotsIn(HangarPlanSlotStateEnum.OPEN),
          })
        }}
      </Pill>
      <span v-if="plan.shared" class="plan-meta__shared">
        <i class="fa-light fa-share-nodes" />
        {{ t("hangarPlanner.shared") }}
      </span>
    </div>

    <PageActions>
      <Btn data-test="hangar-plan-add-slot" @click="addSlot()">
        <i class="fa-light fa-plus" />
        {{ t("hangarPlanner.addSlot") }}
      </Btn>
      <Btn data-test="hangar-plan-add-melt" @click="openMelt()">
        <i class="fa-light fa-fire" />
        {{ t("hangarPlanner.addMelt") }}
      </Btn>
      <Btn
        :to="{ name: 'hangar-plan-slots', params: { id: plan.id } }"
        data-test="hangar-plan-edit-slots"
      >
        <i class="fa-light fa-grid-2" />
        {{ t("hangarPlanner.editSlots") }}
      </Btn>
      <BtnDropdown data-test="hangar-plan-more">
        <template #label>
          <i class="fa-light fa-ellipsis" />
          {{ t("hangarPlanner.more") }}
        </template>
        <Btn :variant="BtnVariantsEnum.BARE" @click="editPlan">
          <i class="fa-light fa-pen" />
          {{ t("hangarPlanner.editPlan") }}
        </Btn>
        <Btn
          v-if="!plan.shared"
          :variant="BtnVariantsEnum.BARE"
          data-test="hangar-plan-share"
          @click="onShare"
        >
          <i class="fa-light fa-share-nodes" />
          {{ t("hangarPlanner.share") }}
        </Btn>
        <Btn
          v-else
          :variant="BtnVariantsEnum.BARE"
          data-test="hangar-plan-copy-share-link"
          @click="onCopyShareLink"
        >
          <i class="fa-light fa-copy" />
          {{ t("hangarPlanner.copyShareLink") }}
        </Btn>
        <Btn
          v-if="plan.shared"
          :variant="BtnVariantsEnum.BARE"
          @click="onUnshare"
        >
          <i class="fa-light fa-link-slash" />
          {{ t("hangarPlanner.unshare") }}
        </Btn>
        <Btn
          :variant="BtnVariantsEnum.BARE"
          :confirm="t('hangarPlanner.confirmAddToWishlist')"
          data-test="hangar-plan-wishlist"
          @click="onAddToWishlist"
        >
          <i class="fa-light fa-star" />
          {{ t("hangarPlanner.addToWishlist") }}
        </Btn>
        <Btn
          v-for="other in otherPlans"
          :key="other.id"
          :variant="BtnVariantsEnum.BARE"
          :to="{
            name: 'hangar-plan-compare',
            params: { id: plan.id, otherId: other.id },
          }"
        >
          <i class="fa-light fa-code-compare" />
          {{ t("hangarPlanner.compareWith", { plan: other.name }) }}
        </Btn>
        <Btn
          :variant="BtnVariantsEnum.BARE"
          :tone="BtnTonesEnum.DANGER"
          :confirm="t('hangarPlanner.confirmDestroy')"
          @click="onDestroy"
        >
          <i class="fa-light fa-trash" />
          {{ t("hangarPlanner.destroyPlan") }}
        </Btn>
      </BtnDropdown>
    </PageActions>

    <FormInput
      v-if="shareUrl"
      :model-value="shareUrl"
      name="shareUrl"
      :label="t('hangarPlanner.shareLink')"
      readonly
      standalone
      data-test="hangar-plan-share-link"
    />

    <DriftAlert v-if="drift?.drifted" :plan-id="plan.id" :drift="drift" />

    <CostTiles v-if="summary" :totals="summary.totals" />
    <Readiness :slots="plan.slots" :costs="summary?.slots" />

    <div class="plan-layout">
      <section class="plan-flow">
        <div
          v-if="tallies.length || pendingIds.length"
          class="plan-tallies"
          data-test="hangar-plan-tallies"
        >
          <Pill
            v-for="tally in tallies"
            :key="tally.key"
            :variant="tally.variant"
          >
            {{
              t(`hangarPlanner.comparison.tallies.${tally.key}`, {
                count: tally.value,
              })
            }}
          </Pill>
          <Btn
            v-if="pendingIds.length"
            :size="BtnSizesEnum.SM"
            :loading="deciding"
            data-test="hangar-plan-keep-pending"
            @click="keep(pendingIds)"
          >
            <i class="fa-light fa-check" />
            {{ t("hangarPlanner.decisions.keepPending") }}
          </Btn>
        </div>
        <Loader :loading="comparisonFetching && !comparison" />
        <HangarFlow
          v-if="comparison"
          :plan="plan"
          :comparison="comparison"
          :summary="summary"
          @decide="decide"
          @route="openRoute"
          @pick="pickShips"
        />
      </section>

      <aside class="plan-side">
        <SummaryPanel :summary="summary" :loading="summaryFetching" />

        <Panel :variant="PanelVariantsEnum.SLIM" data-test="hangar-plan-melts">
          <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
            {{ t("hangarPlanner.melts") }}
          </PanelHeading>
          <PanelBody>
            <p v-if="!plan.melts.length" class="plan-muted">
              {{ t("hangarPlanner.noMelts") }}
            </p>
            <ul class="plan-melts">
              <li v-for="melt in plan.melts" :key="melt.id">
                <div class="plan-melts__row">
                  <span class="plan-melts__name">
                    {{ melt.vehicleName || melt.model.name }}
                    <small v-if="melt.vehicleName" class="plan-muted">
                      {{ melt.model.name }}
                    </small>
                    <small v-if="melt.vehicleMissing" class="plan-warning">
                      {{ t("hangarPlanner.sourceMissing") }}
                    </small>
                  </span>
                  <span class="plan-melts__value">
                    {{ money(melt.value) }}
                    <small v-if="melt.estimated" class="plan-muted">
                      {{ t("hangarPlanner.estimated") }}
                    </small>
                    <Btn
                      :size="BtnSizesEnum.XS"
                      :variant="BtnVariantsEnum.BARE"
                      :aria-label="t('hangarPlanner.editMelt')"
                      @click="openMelt(melt)"
                    >
                      <i class="fa-light fa-pen" />
                    </Btn>
                    <Btn
                      :size="BtnSizesEnum.XS"
                      :variant="BtnVariantsEnum.BARE"
                      :tone="BtnTonesEnum.DANGER"
                      :aria-label="t('hangarPlanner.removeMelt')"
                      @click="removeMelt(melt)"
                    >
                      <i class="fa-light fa-trash" />
                    </Btn>
                  </span>
                </div>
                <MeltContents
                  v-if="melt.pledgeShips.length || melt.pledgeItems.length"
                  :ships="melt.pledgeShips"
                  :items="melt.pledgeItems"
                  class="plan-melts__contents"
                  :data-test="`hangar-plan-melt-contents-${melt.id}`"
                />
              </li>
            </ul>
          </PanelBody>
        </Panel>
      </aside>
    </div>

    <ComparisonDetails v-if="comparison" :comparison="comparison" />
  </template>
</template>

<style lang="scss" scoped>
.plan-description,
.plan-muted {
  color: var(--color-text-dim);
}

.plan-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
  margin-bottom: 16px;
}

.plan-meta__shared {
  font-size: 0.85rem;
  color: var(--color-text-dim);
}

.plan-layout {
  display: grid;
  grid-template-columns: minmax(0, 2fr) minmax(280px, 1fr);
  gap: 16px;
  margin-bottom: 16px;

  @media (max-width: 991px) {
    grid-template-columns: minmax(0, 1fr);
  }
}

.plan-tallies {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
}

.plan-flow,
.plan-side {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.plan-melts {
  margin: 0;
  padding: 0;
  list-style: none;

  li {
    padding: 4px 0;
  }
}

.plan-melts__row {
  display: flex;
  gap: 8px;
  align-items: center;
  justify-content: space-between;
}

.plan-melts__contents {
  margin-top: 4px;
}

.plan-melts__name {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.plan-melts__value {
  display: flex;
  gap: 4px;
  align-items: center;
  white-space: nowrap;
}

.plan-warning {
  color: var(--color-warning);
}
</style>
