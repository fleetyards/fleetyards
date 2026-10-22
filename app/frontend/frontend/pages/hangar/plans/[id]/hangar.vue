<script lang="ts">
export default {
  name: "HangarPlanHangarPage",
};
</script>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import fallbackImage from "@/images/fallback/store_image.webp";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import Loader from "@/shared/components/Loader/index.vue";
import HangarFlow from "@/frontend/components/Hangar/Planner/HangarFlow/index.vue";
import MetricsTable from "@/frontend/components/Hangar/Planner/MetricsTable/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { useI18n } from "@/shared/composables/useI18n";
import {
  HangarPlanModelChangeEnum,
  HangarPlanSlotStateEnum,
  HangarPlanVehicleStatusEnum,
  useHangarPlan,
  useHangarPlanComparison,
  useHangarPlans,
  useHangarPlanSummary,
} from "@/services/fyApi";

const route = useRoute();
const { t } = useI18n();
const { amount, range } = usePlanMoney();

const planId = computed(() => String(route.params.id));

const { data: plan, isLoading } = useHangarPlan(planId);
const { data: comparison, isFetching: comparisonFetching } =
  useHangarPlanComparison(planId);
const { data: summary } = useHangarPlanSummary(planId);
const { data: plans } = useHangarPlans();

const otherPlans = computed(() =>
  (plans.value ?? []).filter((entry) => entry.id !== planId.value),
);

const countOf = (status: HangarPlanVehicleStatusEnum) =>
  (comparison.value?.vehicles ?? []).filter((entry) => entry.status === status)
    .length;

const tallies = computed(() =>
  [
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
    {
      key: "open",
      value: (plan.value?.slots ?? []).filter(
        (slot) => slot.state === HangarPlanSlotStateEnum.OPEN,
      ).length,
    },
  ]
    .map((tally) => ({ variant: PillVariantsEnum.NEUTRAL, ...tally }))
    .filter((tally) => tally.value > 0),
);

// What comes into the hangar and what leaves it, the biggest moves first;
// models the plan leaves alone are only counted.
const moved = computed(() =>
  (comparison.value?.models ?? []).filter(
    (diff) => diff.change !== HangarPlanModelChangeEnum.UNCHANGED,
  ),
);

const byDelta = (side: "in" | "out") =>
  moved.value
    .filter((diff) =>
      side === "in"
        ? diff.rightCount > diff.leftCount
        : diff.rightCount < diff.leftCount,
    )
    .map((diff) => ({ ...diff, delta: diff.rightCount - diff.leftCount }))
    .sort(
      (a, b) =>
        Math.abs(b.delta) - Math.abs(a.delta) ||
        a.model.name.localeCompare(b.model.name),
    );

const changeColumns = computed(() =>
  (["in", "out"] as const)
    .map((side) => ({ side, rows: byDelta(side) }))
    .filter((column) => column.rows.length),
);

const unchangedCount = computed(
  () =>
    (comparison.value?.models ?? []).filter(
      (diff) => diff.change === HangarPlanModelChangeEnum.UNCHANGED,
    ).length,
);

const totals = computed(() => summary.value?.totals);

const incomplete = computed(
  () =>
    !!totals.value &&
    (totals.value.unresolvedCount > 0 || totals.value.openSlotsCount > 0),
);
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

  <div class="plan-hangar__head">
    <div>
      <Heading size="hero" hero>
        {{ t("hangarPlanner.comparison.title") }}
      </Heading>
      <p class="plan-hangar__lead">{{ t("hangarPlanner.comparison.lead") }}</p>
    </div>
    <BtnDropdown v-if="otherPlans.length" data-test="hangar-plan-compare-plans">
      <template #label>
        <i class="fa-light fa-code-compare" />
        {{ t("hangarPlanner.comparison.anotherPlan") }}
      </template>
      <Btn
        v-for="other in otherPlans"
        :key="other.id"
        :variant="BtnVariantsEnum.BARE"
        :to="{
          name: 'hangar-plan-compare',
          params: { id: planId, otherId: other.id },
        }"
      >
        {{ other.name }}
      </Btn>
    </BtnDropdown>
  </div>

  <Loader :loading="isLoading" />

  <template v-if="plan">
    <div
      v-if="tallies.length"
      class="plan-hangar__tallies"
      data-test="hangar-plan-tallies"
    >
      <Pill v-for="tally in tallies" :key="tally.key" :variant="tally.variant">
        {{
          t(`hangarPlanner.comparison.tallies.${tally.key}`, {
            count: tally.value,
          })
        }}
      </Pill>
    </div>

    <Loader :loading="comparisonFetching && !comparison" />
    <HangarFlow
      v-if="comparison"
      :plan="plan"
      :comparison="comparison"
      :summary="summary"
    />

    <div v-if="comparison" class="plan-hangar__foot">
      <Panel :variant="PanelVariantsEnum.SLIM" :outer-spacing="false">
        <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
          {{ t("hangarPlanner.comparison.changes") }}
        </PanelHeading>
        <PanelBody>
          <p v-if="!moved.length" class="plan-hangar__muted">
            {{ t("hangarPlanner.comparison.noChanges") }}
          </p>
          <div v-else class="plan-hangar__changes">
            <section
              v-for="column in changeColumns"
              :key="column.side"
              class="plan-hangar__change-column"
            >
              <h4>
                {{ t(`hangarPlanner.comparison.changeSides.${column.side}`) }}
              </h4>
              <ul>
                <li
                  v-for="diff in column.rows"
                  :key="diff.model.id"
                  data-test="hangar-plan-model-diff"
                >
                  <img
                    :src="diff.model.image?.smallUrl || fallbackImage"
                    alt=""
                    class="plan-hangar__change-image"
                    loading="lazy"
                  />
                  <span class="plan-hangar__change-text">
                    <strong>{{ diff.model.name }}</strong>
                    <span class="plan-hangar__muted">
                      {{ t(`hangarPlanner.changes.${diff.change}`) }} ·
                      {{ diff.leftCount }} → {{ diff.rightCount }}
                    </span>
                  </span>
                  <span
                    class="plan-hangar__change-delta"
                    :class="{
                      'plan-hangar__change-delta--out': diff.delta < 0,
                    }"
                  >
                    {{ diff.delta > 0 ? "+" : "−" }}{{ Math.abs(diff.delta) }}
                  </span>
                </li>
              </ul>
            </section>
          </div>
          <p v-if="moved.length && unchangedCount" class="plan-hangar__muted">
            {{
              t("hangarPlanner.comparison.unchangedCount", {
                count: unchangedCount,
              })
            }}
          </p>
        </PanelBody>
      </Panel>

      <Panel
        v-if="totals"
        :variant="PanelVariantsEnum.SLIM"
        :outer-spacing="false"
      >
        <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
          {{ t("hangarPlanner.comparison.costsTitle") }}
        </PanelHeading>
        <PanelBody>
          <p class="plan-hangar__sum" data-test="hangar-plan-hangar-costs">
            <span>
              <strong>{{ range(totals.spendMin, totals.spendMax) }}</strong>
              {{ t("hangarPlanner.summary.spend") }}
            </span>
            <i class="fa-solid fa-minus" aria-hidden="true" />
            <span>
              <strong>{{ amount(totals.meltCredit) }}</strong>
              {{ t("hangarPlanner.summary.meltCredit") }}
            </span>
            <i class="fa-solid fa-minus" aria-hidden="true" />
            <span>
              <strong>{{ amount(totals.startingCredit) }}</strong>
              {{ t("hangarPlanner.summary.startingCredit") }}
            </span>
            <i class="fa-solid fa-equals" aria-hidden="true" />
            <span>
              <strong>
                {{ range(totals.cashNeededMin, totals.cashNeededMax) }}
              </strong>
              {{ t("hangarPlanner.summary.cashNeeded") }}
            </span>
          </p>
          <p v-if="incomplete" class="plan-hangar__muted">
            {{ t("hangarPlanner.summary.incomplete") }}
          </p>
        </PanelBody>
      </Panel>
    </div>

    <Panel
      v-if="comparison"
      :variant="PanelVariantsEnum.SLIM"
      :outer-spacing="false"
      class="plan-hangar__stats"
    >
      <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
        {{ t("hangarPlanner.metrics.title") }}
      </PanelHeading>
      <PanelBody>
        <MetricsTable
          :left="comparison.metrics.live"
          :right="comparison.metrics.plan"
          :left-label="t('hangarPlanner.comparison.hangar')"
          :right-label="t('hangarPlanner.comparison.after')"
        />
      </PanelBody>
    </Panel>
  </template>
</template>

<style lang="scss" scoped>
.plan-hangar__head {
  display: flex;
  flex-wrap: wrap;
  gap: 16px 24px;
  align-items: flex-end;
  justify-content: space-between;
  margin-bottom: 20px;
}

.plan-hangar__lead {
  max-width: 70ch;
  margin: 0;
  color: var(--color-text-dim);
}

.plan-hangar__tallies {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
  margin-bottom: 20px;
}

.plan-hangar__foot {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  margin-top: 24px;

  > * {
    flex: 1 1 380px;
    min-width: 0;
  }
}

.plan-hangar__changes {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 16px 24px;
  margin-bottom: 12px;
}

.plan-hangar__change-column {
  h4 {
    margin: 0 0 8px;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    font-weight: 400;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim);
  }

  ul {
    display: flex;
    flex-direction: column;
    gap: 6px;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  li {
    display: flex;
    gap: 10px;
    align-items: center;
    padding: 6px 8px;
    border: 1px solid var(--color-edge-faint);
    border-radius: 8px;
  }
}

.plan-hangar__change-image {
  flex: none;
  width: 56px;
  height: 32px;
  object-fit: cover;
  border-radius: 4px;
}

.plan-hangar__change-text {
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

.plan-hangar__change-delta {
  padding: 2px 8px;
  border-radius: 4px;
  background: color-mix(in srgb, var(--color-primary) 20%, transparent);
  color: var(--color-primary-tint);
  font-weight: 600;
}

.plan-hangar__change-delta--out {
  background: rgba(122, 130, 136, 0.18);
  color: var(--color-text);
}

.plan-hangar__sum {
  display: flex;
  flex-wrap: wrap;
  gap: 10px 14px;
  align-items: center;
  margin: 0 0 8px;

  strong {
    font-size: 1.1rem;
    color: var(--color-lifted);
  }

  i {
    font-size: 0.75rem;
    color: var(--color-muted);
  }
}

.plan-hangar__muted {
  margin: 0;
  color: var(--color-text-dim);
}

.plan-hangar__stats {
  margin-top: 16px;
}
</style>
