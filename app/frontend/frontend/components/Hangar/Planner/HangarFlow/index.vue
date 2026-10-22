<script lang="ts">
export default {
  name: "HangarPlannerHangarFlow",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { useI18n } from "@/shared/composables/useI18n";
import fallbackImage from "@/images/fallback/store_image.webp";
import {
  type HangarPlan,
  type HangarPlanAcquisition,
  type HangarPlanComparison,
  type HangarPlanModel,
  type HangarPlanSlot,
  type HangarPlanSummary,
  HangarPlanSlotStateEnum,
  HangarPlanStartKindEnum,
  HangarPlanVehicleStatusEnum,
} from "@/services/fyApi";

type Props = {
  plan: HangarPlan;
  comparison: HangarPlanComparison;
  summary?: HangarPlanSummary;
};

const props = withDefaults(defineProps<Props>(), {
  summary: undefined,
});

const { t } = useI18n();
const { money, range } = usePlanMoney();

type Card = {
  title: string;
  sub?: string;
  model?: HangarPlanModel;
  pill?: { variant: `${PillVariantsEnum}`; label: string };
  tone?: "warning";
};

type RowGroup = "decided" | "buy" | "undecided" | "melt" | "unassigned";

type Row = {
  key: string;
  group: RowGroup;
  testId: string;
  left?: Card;
  // Shown in a dashed card where nothing stands on that side.
  leftNone?: string;
  action: { kind: string; icon?: string; label: string; detail?: string };
  right?: Card;
  rightNone?: string;
};

type Group = { key: RowGroup; rows: Row[]; collapsible: boolean };

const decidedPill = computed(() => ({
  variant: PillVariantsEnum.SUCCESS,
  label: t("hangarPlanner.states.decided"),
}));

// Every route the plan takes, by the slot and candidate it fills.
const routes = computed(() =>
  props.plan.slots.flatMap((slot) =>
    slot.state === HangarPlanSlotStateEnum.DECIDED
      ? (slot.candidates[0]?.acquisitions ?? []).map((acquisition, index) => ({
          slot,
          model: slot.candidates[0].model,
          acquisition,
          index,
        }))
      : [],
  ),
);

const routeCost = (acquisition: HangarPlanAcquisition) => {
  const prices = [
    acquisition.price,
    ...acquisition.steps.map((step) => step.price),
  ];
  if (prices.some((price) => price === null || price === undefined)) {
    return null;
  }
  return prices.reduce<number>((sum, price) => sum + (price ?? 0), 0);
};

const slotSub = (slot: HangarPlanSlot, index: number) =>
  slot.quantity > 1
    ? `${slot.label} · ${t("hangarPlanner.comparison.flow.shipOf", {
        number: index + 1,
        count: slot.quantity,
      })}`
    : slot.label;

const hangarCard = (
  name: string | null | undefined,
  model: HangarPlanModel,
): Card => ({
  title: name || model.name,
  sub: [name ? model.name : undefined, model.manufacturerName]
    .filter(Boolean)
    .join(" · "),
  model,
});

const statusOrder: HangarPlanVehicleStatusEnum[] = [
  HangarPlanVehicleStatusEnum.UPGRADED,
  HangarPlanVehicleStatusEnum.KEPT,
];

const keptRows = computed<Row[]>(() =>
  props.comparison.vehicles
    .filter((entry) => statusOrder.includes(entry.status))
    .sort(
      (a, b) => statusOrder.indexOf(a.status) - statusOrder.indexOf(b.status),
    )
    .map((entry) => {
      const route = routes.value.find(
        (candidate) =>
          candidate.acquisition.sourceVehicleId === entry.vehicleId,
      );
      const upgraded = entry.status === HangarPlanVehicleStatusEnum.UPGRADED;
      const target = upgraded
        ? (entry.targetModel ?? entry.model)
        : entry.model;
      const steps = route?.acquisition.steps.length ?? 0;

      return {
        key: entry.vehicleId,
        group: "decided" as const,
        testId: "hangar-plan-vehicle-status",
        left: hangarCard(entry.name, entry.model),
        action: upgraded
          ? {
              kind: "upgraded",
              icon: "fa-light fa-arrow-up-right",
              label: t("hangarPlanner.vehicleStatuses.upgraded"),
              detail: t("hangarPlanner.comparison.flow.steps", {
                count: steps,
                price: money(route ? routeCost(route.acquisition) : null),
              }),
            }
          : {
              kind: "kept",
              label: t("hangarPlanner.vehicleStatuses.kept"),
              detail: money(0),
            },
        right: {
          title: target.name,
          sub: route ? slotSub(route.slot, route.index) : undefined,
          model: target,
          pill: route ? decidedPill.value : undefined,
        },
      };
    }),
);

const leavingRows = computed<Row[]>(() =>
  props.comparison.vehicles
    .filter(
      (entry) =>
        entry.status === HangarPlanVehicleStatusEnum.MELTED ||
        entry.status === HangarPlanVehicleStatusEnum.UNASSIGNED,
    )
    .map((entry) => {
      const melted = entry.status === HangarPlanVehicleStatusEnum.MELTED;
      const melt = props.plan.melts.find(
        (candidate) => candidate.vehicleId === entry.vehicleId,
      );

      return {
        key: entry.vehicleId,
        group: melted ? ("melt" as const) : ("unassigned" as const),
        testId: "hangar-plan-vehicle-status",
        left: hangarCard(entry.name, entry.model),
        action: melted
          ? {
              kind: "melted",
              icon: "fa-light fa-fire",
              label: t("hangarPlanner.vehicleStatuses.melted"),
              detail: melt
                ? [
                    t("hangarPlanner.comparison.meltCredit", {
                      value: money(melt.value),
                    }),
                    melt.estimated ? t("hangarPlanner.estimated") : undefined,
                  ]
                    .filter(Boolean)
                    .join(" · ")
                : undefined,
            }
          : {
              kind: "unassigned",
              label: t("hangarPlanner.vehicleStatuses.unassigned"),
            },
        rightNone: melted
          ? t("hangarPlanner.comparison.leaves")
          : t("hangarPlanner.comparison.notInPlan"),
      };
    }),
);

const slotCost = (slot: HangarPlanSlot) =>
  props.summary?.slots.find((cost) => cost.slotId === slot.id);

const neededRows = computed<Row[]>(() => {
  const notOwned = t("hangarPlanner.comparison.notOwned");

  const bought = routes.value
    .filter(
      (route) => route.acquisition.startKind !== HangarPlanStartKindEnum.OWNED,
    )
    .map((route) => ({
      key: route.acquisition.id,
      group: "buy" as const,
      testId: "hangar-plan-flow-purchase",
      leftNone: notOwned,
      action: {
        kind: "buy",
        icon: "fa-light fa-cart-shopping",
        label: t(`hangarPlanner.startKinds.${route.acquisition.startKind}`),
        detail: money(routeCost(route.acquisition)),
      },
      right: {
        title: route.model.name,
        sub: slotSub(route.slot, route.index),
        model: route.model,
        pill: decidedPill.value,
      },
    }));

  const gaps = props.comparison.gaps.map((gap) => ({
    key: `gap-${gap.slotId}`,
    group: "decided" as const,
    testId: "hangar-plan-gap",
    leftNone: notOwned,
    action: {
      kind: "gap",
      icon: "fa-light fa-route",
      label: t("hangarPlanner.comparison.flow.noRoute"),
      detail: t("hangarPlanner.comparison.flow.notCounted"),
    },
    right: {
      title: `${gap.count} × ${gap.model.name}`,
      sub: gap.label,
      model: gap.model,
      tone: "warning" as const,
    },
  }));

  const undecided = props.plan.slots
    .filter((slot) => slot.state === HangarPlanSlotStateEnum.UNDECIDED)
    .map((slot) => {
      const cost = slotCost(slot);

      return {
        key: `undecided-${slot.id}`,
        group: "undecided" as const,
        testId: "hangar-plan-flow-undecided",
        leftNone: notOwned,
        action: {
          kind: "buy",
          icon: "fa-light fa-cart-shopping",
          label: t("hangarPlanner.startKinds.store"),
          detail: cost ? range(cost.minCost, cost.maxCost) : undefined,
        },
        right: {
          title: slot.candidates
            .map((candidate) => candidate.model.name)
            .join(" / "),
          sub: slot.label,
          model: slot.candidates[0]?.model,
          pill: {
            variant: PillVariantsEnum.WARNING,
            label: t("hangarPlanner.states.undecided"),
          },
          tone: "warning" as const,
        },
      };
    });

  const open = props.plan.slots
    .filter((slot) => slot.state === HangarPlanSlotStateEnum.OPEN)
    .map((slot) => ({
      key: `open-${slot.id}`,
      group: "undecided" as const,
      testId: "hangar-plan-flow-open",
      leftNone: notOwned,
      action: {
        kind: "open",
        label: t("hangarPlanner.states.open"),
        detail: t("hangarPlanner.comparison.flow.noShip"),
      },
      rightNone: `${slot.label} · ${t("hangarPlanner.comparison.flow.noShip")}`,
    }));

  return [...bought, ...gaps, ...undecided, ...open];
});

// What the plan settles comes first, then what it still has to buy or decide,
// then what leaves the hangar; ships the plan has no use for wait folded.
const groupOrder: RowGroup[] = [
  "decided",
  "buy",
  "undecided",
  "melt",
  "unassigned",
];

const groups = computed<Group[]>(() => {
  const rows = [...keptRows.value, ...neededRows.value, ...leavingRows.value];

  return groupOrder
    .map((key) => ({
      key,
      rows: rows.filter((row) => row.group === key),
      collapsible: key === "unassigned",
    }))
    .filter((group) => group.rows.length);
});

const expanded = ref<RowGroup[]>([]);

const toggle = (key: RowGroup) => {
  expanded.value = expanded.value.includes(key)
    ? expanded.value.filter((entry) => entry !== key)
    : [...expanded.value, key];
};

const shown = (group: Group) =>
  !group.collapsible || expanded.value.includes(group.key);

const imageOf = (model?: HangarPlanModel) =>
  model?.image?.smallUrl || fallbackImage;
</script>

<template>
  <div class="hangar-flow" role="table">
    <div class="hangar-flow__row hangar-flow__row--head" role="row">
      <span role="columnheader">
        {{ t("hangarPlanner.comparison.yourShips") }}
      </span>
      <span role="columnheader">
        {{ t("hangarPlanner.comparison.happens") }}
      </span>
      <span role="columnheader">
        {{ t("hangarPlanner.comparison.plan") }}
      </span>
    </div>

    <p v-if="!comparison.vehicles.length" class="hangar-flow__muted">
      {{ t("hangarPlanner.comparison.noShips") }}
    </p>

    <template v-for="(group, groupIndex) in groups" :key="group.key">
      <div v-if="groupIndex > 0" class="hangar-flow__divider" />
      <button
        v-if="group.collapsible"
        type="button"
        class="hangar-flow__toggle"
        :aria-expanded="shown(group)"
        :data-test="`hangar-plan-flow-toggle-${group.key}`"
        @click="toggle(group.key)"
      >
        <i
          class="fa-light"
          :class="shown(group) ? 'fa-chevron-down' : 'fa-chevron-right'"
          aria-hidden="true"
        />
        {{
          t("hangarPlanner.comparison.flow.notInPlan", {
            count: group.rows.length,
          })
        }}
      </button>
      <div
        v-for="row in shown(group) ? group.rows : []"
        :key="row.key"
        class="hangar-flow__row"
        role="row"
        :data-test="row.testId"
      >
        <div
          v-if="row.left"
          class="hangar-flow__card"
          :class="{ 'hangar-flow__card--warning': row.left.tone }"
          role="cell"
        >
          <img
            :src="imageOf(row.left.model)"
            alt=""
            class="hangar-flow__image"
            loading="lazy"
          />
          <span class="hangar-flow__text">
            <strong>{{ row.left.title }}</strong>
            <span v-if="row.left.sub" class="hangar-flow__muted">
              {{ row.left.sub }}
            </span>
          </span>
        </div>
        <div
          v-else
          class="hangar-flow__card hangar-flow__card--none"
          role="cell"
        >
          {{ row.leftNone }}
        </div>

        <div
          class="hangar-flow__action"
          :class="`hangar-flow__action--${row.action.kind}`"
          role="cell"
        >
          <span class="hangar-flow__tag">
            <strong>
              <i v-if="row.action.icon" :class="row.action.icon" />
              {{ row.action.label }}
            </strong>
            <span v-if="row.action.detail">{{ row.action.detail }}</span>
          </span>
        </div>

        <div
          v-if="row.right"
          class="hangar-flow__card"
          :class="{ 'hangar-flow__card--warning': row.right.tone }"
          role="cell"
        >
          <img
            :src="imageOf(row.right.model)"
            alt=""
            class="hangar-flow__image"
            loading="lazy"
          />
          <span class="hangar-flow__text">
            <strong>{{ row.right.title }}</strong>
            <span v-if="row.right.sub" class="hangar-flow__muted">
              {{ row.right.sub }}
            </span>
          </span>
          <Pill v-if="row.right.pill" :variant="row.right.pill.variant">
            {{ row.right.pill.label }}
          </Pill>
        </div>
        <div
          v-else
          class="hangar-flow__card hangar-flow__card--none"
          role="cell"
        >
          {{ row.rightNone }}
        </div>
      </div>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.hangar-flow {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.hangar-flow__row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 220px minmax(0, 1fr);
  gap: 0 16px;
  align-items: center;
}

.hangar-flow__row--head {
  padding: 0 4px 4px;

  span {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim);
  }

  span:nth-child(2) {
    text-align: center;
  }
}

.hangar-flow__card {
  display: flex;
  gap: 12px;
  align-items: center;
  min-height: 64px;
  padding: 10px 14px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
  background: var(--color-control);
}

.hangar-flow__card--none {
  justify-content: center;
  border-style: dashed;
  background: transparent;
  color: var(--color-text-dim);
  font-size: 0.85rem;
}

.hangar-flow__card--warning {
  border-color: var(--color-warning);
}

.hangar-flow__image {
  flex: none;
  width: 72px;
  height: 42px;
  object-fit: cover;
  border-radius: 6px;
}

.hangar-flow__text {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 2px;
  min-width: 0;

  strong {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    color: var(--color-lifted);
  }
}

.hangar-flow__muted {
  font-size: 0.8rem;
  color: var(--color-text-dim);
}

.hangar-flow__toggle {
  display: flex;
  gap: 8px;
  align-items: center;
  align-self: flex-start;
  min-height: 44px;
  padding: 0 12px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: var(--color-text);
  font: inherit;
  cursor: pointer;

  &:hover {
    background: var(--color-control-hover);
    color: var(--color-lifted);
  }

  &:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: 1px;
  }
}

.hangar-flow__divider {
  height: 1px;
  margin: 6px 0;
  background: var(--color-edge-faint);
}

// The connector carries what happens to a ship: a solid line where it reaches
// the plan, dashed where it leaves the hangar or has no way in yet.
.hangar-flow__action {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  height: 64px;

  &::before {
    content: "";
    position: absolute;
    top: 50%;
    right: 10px;
    left: 0;
    border-top: 1px solid var(--color-edge-strong);
  }

  &::after {
    content: "";
    position: absolute;
    top: calc(50% - 4px);
    right: 2px;
    border-top: 4px solid transparent;
    border-bottom: 4px solid transparent;
    border-left: 8px solid var(--color-edge-strong);
  }
}

.hangar-flow__action--upgraded {
  &::before {
    border-top: 2px solid var(--color-primary);
  }

  &::after {
    border-left-color: var(--color-primary);
  }

  .hangar-flow__tag {
    border-color: var(--color-primary);
  }
}

.hangar-flow__action--melted,
.hangar-flow__action--unassigned {
  &::before {
    right: 30%;
    border-top-style: dashed;
  }

  &::after {
    display: none;
  }
}

.hangar-flow__action--gap {
  &::before {
    border-top: 1px dashed var(--color-warning);
  }

  &::after {
    border-left-color: var(--color-warning);
  }

  .hangar-flow__tag {
    border-color: var(--color-warning);
    color: var(--color-warning);

    strong {
      color: var(--color-warning);
    }
  }
}

.hangar-flow__action--open::before {
  border-top-style: dotted;
}

.hangar-flow__tag {
  position: relative;
  z-index: 1;
  display: inline-flex;
  flex-direction: column;
  gap: 1px;
  align-items: center;
  padding: 5px 10px;
  border: 1px solid var(--color-edge);
  border-radius: 8px;
  background: var(--color-gray-black);
  font-size: 0.75rem;
  white-space: nowrap;

  strong {
    font-size: 0.85rem;
    color: var(--color-lifted);
  }

  i {
    margin-right: 4px;
  }
}

@media (max-width: 991px) {
  .hangar-flow__row {
    grid-template-columns: minmax(0, 1fr);
    gap: 4px;
    padding-bottom: 8px;
    border-bottom: 1px solid var(--color-edge-faint);
  }

  .hangar-flow__row--head {
    display: none;
  }

  .hangar-flow__action {
    justify-content: flex-start;
    height: auto;

    &::before,
    &::after {
      display: none;
    }
  }
}
</style>
