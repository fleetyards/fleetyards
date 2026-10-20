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
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import Loader from "@/shared/components/Loader/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import SlotCard from "@/frontend/components/Hangar/Planner/SlotCard/index.vue";
import SummaryPanel from "@/frontend/components/Hangar/Planner/SummaryPanel/index.vue";
import ComparisonPanel from "@/frontend/components/Hangar/Planner/ComparisonPanel/index.vue";
import DriftAlert from "@/frontend/components/Hangar/Planner/DriftAlert/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import copyText from "@/shared/utils/CopyText";
import {
  type HangarPlanMelt,
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
const { data: comparison, isFetching: comparisonFetching } =
  useHangarPlanComparison(planId);
const { data: drift } = useHangarPlanDrift(planId);
const { data: plans } = useHangarPlans();

const otherPlans = computed(() =>
  (plans.value ?? []).filter((entry) => entry.id !== planId.value),
);

const slotCost = (slotId: string) =>
  summary.value?.slots.find((cost) => cost.slotId === slotId);

const openModal = (
  component: () => Promise<Component>,
  props: Record<string, unknown> = {},
) => comlink.emit("open-modal", { component, props });

const editPlan = () =>
  openModal(
    () => import("@/frontend/components/Hangar/Planner/PlanModal/index.vue"),
    { plan: plan.value },
  );

const addSlot = () =>
  openModal(
    () => import("@/frontend/components/Hangar/Planner/SlotModal/index.vue"),
    { planId: planId.value },
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

    <PageActions>
      <Btn data-test="hangar-plan-add-slot" @click="addSlot">
        <i class="fa-light fa-plus" />
        {{ t("hangarPlanner.addSlot") }}
      </Btn>
      <Btn data-test="hangar-plan-add-melt" @click="openMelt()">
        <i class="fa-light fa-fire" />
        {{ t("hangarPlanner.addMelt") }}
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

    <div class="plan-layout">
      <section class="plan-slots">
        <p v-if="!plan.slots.length" class="plan-muted">
          {{ t("hangarPlanner.noSlots") }}
        </p>
        <SlotCard
          v-for="slot in plan.slots"
          :key="slot.id"
          :plan-id="plan.id"
          :slot="slot"
          :cost="slotCost(slot.id)"
        />
      </section>

      <aside class="plan-side">
        <SummaryPanel :summary="summary" :loading="summaryFetching" />

        <Panel :variant="PanelVariantsEnum.SLIM" data-test="hangar-plan-melts">
          <PanelHeading compact divider>
            {{ t("hangarPlanner.melts") }}
          </PanelHeading>
          <PanelBody>
            <p v-if="!plan.melts.length" class="plan-muted">
              {{ t("hangarPlanner.noMelts") }}
            </p>
            <ul class="plan-melts">
              <li v-for="melt in plan.melts" :key="melt.id">
                <span>
                  {{ melt.vehicleName || melt.model.name }}
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
              </li>
            </ul>
          </PanelBody>
        </Panel>
      </aside>
    </div>

    <ComparisonPanel :comparison="comparison" :loading="comparisonFetching" />
  </template>
</template>

<style lang="scss" scoped>
.plan-description,
.plan-muted {
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

.plan-slots,
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
    display: flex;
    gap: 8px;
    align-items: center;
    justify-content: space-between;
    padding: 4px 0;
  }
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
