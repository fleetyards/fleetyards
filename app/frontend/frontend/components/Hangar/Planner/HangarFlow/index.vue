<script lang="ts">
export default {
  name: "HangarPlannerHangarFlow",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import {
  type HangarFlowDecision,
  hangarFlowDecisionIcons,
} from "@/frontend/components/Hangar/Planner/HangarFlow/types";
import { useI18n } from "@/shared/composables/useI18n";
import fallbackImage from "@/images/fallback/store_image.webp";
import {
  type HangarPlan,
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
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

const emit = defineEmits<{
  decide: [vehicleId: string, decision: HangarFlowDecision];
  route: [candidate: HangarPlanCandidate, acquisition?: HangarPlanAcquisition];
  pick: [slot: HangarPlanSlot];
}>();

const { t } = useI18n();
const { money, range } = usePlanMoney();

type Card = {
  title: string;
  sub?: string;
  model?: HangarPlanModel;
  pill?: { variant: `${PillVariantsEnum}`; label: string };
  tone?: "warning";
};

type RowGroup = "slots" | "ships" | "kept" | "unassigned";

type Row = {
  key: string;
  group: RowGroup;
  // Where the row stands in its group: slots in the plan's order, ships in the
  // hangar's, so deciding on one never moves it.
  order: number;
  testId: string;
  left?: Card;
  // Shown in a dashed card where nothing stands on that side.
  leftNone?: string;
  action: { kind: string; icon?: string; label: string; detail?: string };
  right?: Card;
  rightNone?: string;
  // A hangar ship the plan has not settled, offered every way to settle it.
  vehicleId?: string;
  decisions?: HangarFlowDecision[];
  // How the slot side is worked on: ships to pick for an empty slot, or a
  // route to plan to one of its ships, or to edit.
  slotAction?:
    | { kind: "pick"; slot: HangarPlanSlot }
    | {
        kind: "route";
        candidates: HangarPlanCandidate[];
        acquisition?: HangarPlanAcquisition;
      };
};

type Group = { key: RowGroup; rows: Row[]; collapsible: boolean };

// Room for every row one slot can have: one per route, plus its gap.
const SLOT_ROWS = 1000;

const slotOrder = (slotId: string) =>
  props.plan.slots.findIndex((slot) => slot.id === slotId) * SLOT_ROWS;

const shipOrder = (vehicleId: string) =>
  props.comparison.vehicles.findIndex((entry) => entry.vehicleId === vehicleId);

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
          candidate: slot.candidates[0],
          model: slot.candidates[0].model,
          acquisition,
          index,
        }))
      : [],
  ),
);

const editRoute = (route?: {
  candidate: HangarPlanCandidate;
  acquisition: HangarPlanAcquisition;
}) =>
  route
    ? {
        kind: "route" as const,
        candidates: [route.candidate],
        acquisition: route.acquisition,
      }
    : undefined;

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
        group: upgraded ? ("ships" as const) : ("kept" as const),
        order: shipOrder(entry.vehicleId),
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
        // Kept without a slot: the plan only noted the decision, so it can be
        // taken back here.
        vehicleId: route ? undefined : entry.vehicleId,
        decisions: route ? undefined : (["pending"] as HangarFlowDecision[]),
        slotAction: editRoute(route),
      };
    }),
);

const settle: HangarFlowDecision[] = ["keep", "upgrade", "melt"];

const reviewRows = computed<Row[]>(() =>
  props.comparison.vehicles
    .filter(
      (entry) =>
        entry.status === HangarPlanVehicleStatusEnum.PENDING ||
        entry.status === HangarPlanVehicleStatusEnum.CHANGE,
    )
    .map((entry) => {
      const change = entry.status === HangarPlanVehicleStatusEnum.CHANGE;

      return {
        key: entry.vehicleId,
        group: "ships" as const,
        order: shipOrder(entry.vehicleId),
        testId: "hangar-plan-vehicle-review",
        left: hangarCard(entry.name, entry.model),
        action: change
          ? {
              kind: "change",
              icon: "fa-light fa-arrows-rotate",
              label: t("hangarPlanner.vehicleStatuses.change"),
            }
          : {
              kind: "pending",
              icon: "fa-light fa-circle-question",
              label: t("hangarPlanner.vehicleStatuses.pending"),
            },
        rightNone: t("hangarPlanner.comparison.flow.toDecide"),
        vehicleId: entry.vehicleId,
        decisions: [...settle, change ? "pending" : "change"],
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
        group: melted ? ("ships" as const) : ("unassigned" as const),
        order: shipOrder(entry.vehicleId),
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
        vehicleId: entry.vehicleId,
        decisions: melted ? undefined : [...settle, "change"],
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
      group: "slots" as const,
      order: slotOrder(route.slot.id) + route.index,
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
      slotAction: editRoute(route),
    }));

  const gaps = props.comparison.gaps.map((gap) => {
    const candidate = props.plan.slots.find((slot) => slot.id === gap.slotId)
      ?.candidates[0];

    return {
      key: `gap-${gap.slotId}`,
      group: "slots" as const,
      order: slotOrder(gap.slotId) + SLOT_ROWS - 1,
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
      slotAction: candidate
        ? { kind: "route" as const, candidates: [candidate] }
        : undefined,
    };
  });

  const undecided = props.plan.slots
    .filter((slot) => slot.state === HangarPlanSlotStateEnum.UNDECIDED)
    .map((slot) => {
      const cost = slotCost(slot);

      return {
        key: `undecided-${slot.id}`,
        group: "slots" as const,
        order: slotOrder(slot.id),
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
        slotAction: { kind: "route" as const, candidates: slot.candidates },
      };
    });

  const open = props.plan.slots
    .filter((slot) => slot.state === HangarPlanSlotStateEnum.OPEN)
    .map((slot) => ({
      key: `open-${slot.id}`,
      group: "slots" as const,
      order: slotOrder(slot.id),
      testId: "hangar-plan-flow-open",
      leftNone: notOwned,
      action: {
        kind: "open",
        label: t("hangarPlanner.states.open"),
        detail: t("hangarPlanner.comparison.flow.noShip"),
      },
      rightNone: `${slot.label} · ${t("hangarPlanner.comparison.flow.noShip")}`,
      slotAction: { kind: "pick" as const, slot },
    }));

  return [...bought, ...gaps, ...undecided, ...open];
});

// The plan's slots come first, so one just added shows above the ships; then
// the ships being worked on. Ships kept as they are, and those the plan has no
// use for, wait folded.
const groupOrder: RowGroup[] = ["slots", "ships", "kept", "unassigned"];

const folded: RowGroup[] = ["kept", "unassigned"];

const groups = computed<Group[]>(() => {
  const rows = [
    ...reviewRows.value,
    ...keptRows.value,
    ...neededRows.value,
    ...leavingRows.value,
  ];

  return groupOrder
    .map((key) => ({
      key,
      rows: rows
        .filter((row) => row.group === key)
        .sort((a, b) => a.order - b.order),
      collapsible: folded.includes(key),
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

const decide = (row: Row, decision: HangarFlowDecision) => {
  if (row.vehicleId) emit("decide", row.vehicleId, decision);
};

const pick = (row: Row) => {
  if (row.slotAction?.kind === "pick") emit("pick", row.slotAction.slot);
};

const routeCandidates = (row: Row) =>
  row.slotAction?.kind === "route" ? row.slotAction.candidates : [];

const routeAcquisition = (row: Row) =>
  row.slotAction?.kind === "route" ? row.slotAction.acquisition : undefined;

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
          t(`hangarPlanner.comparison.flow.folded.${group.key}`, {
            count: group.rows.length,
          })
        }}
      </button>
      <div
        v-for="row in shown(group) ? group.rows : []"
        :key="row.key"
        class="hangar-flow__row"
        :class="`hangar-flow__row--${row.action.kind}`"
        role="row"
        :data-test="row.testId"
      >
        <div
          class="hangar-flow__card"
          :class="{
            'hangar-flow__card--none': !row.left,
            'hangar-flow__card--warning': row.left?.tone,
          }"
          role="cell"
        >
          <template v-if="row.left">
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
          </template>
          <template v-else>{{ row.leftNone }}</template>
          <span
            v-if="routeCandidates(row).length"
            class="hangar-flow__route-action"
          >
            <Btn
              v-if="routeAcquisition(row)"
              :size="BtnSizesEnum.XS"
              :variant="BtnVariantsEnum.BARE"
              :aria-label="
                t('hangarPlanner.editRoute', { ship: row.right?.title })
              "
              :title="t('hangarPlanner.editRoute', { ship: row.right?.title })"
              data-test="hangar-plan-flow-edit-route"
              @click="
                emit('route', routeCandidates(row)[0], routeAcquisition(row))
              "
            >
              <i class="fa-light fa-route" aria-hidden="true" />
            </Btn>
            <Btn
              v-else-if="routeCandidates(row).length === 1"
              :size="BtnSizesEnum.XS"
              data-test="hangar-plan-flow-add-route"
              @click="emit('route', routeCandidates(row)[0])"
            >
              <i class="fa-light fa-route" aria-hidden="true" />
              {{ t("hangarPlanner.addRouteShort") }}
            </Btn>
            <BtnDropdown
              v-else-if="routeCandidates(row).length"
              :size="BtnSizesEnum.XS"
              expand-left
              data-test="hangar-plan-flow-add-route"
            >
              <template #label>
                <i class="fa-light fa-route" aria-hidden="true" />
                {{ t("hangarPlanner.addRouteShort") }}
              </template>
              <Btn
                v-for="candidate in routeCandidates(row)"
                :key="candidate.id"
                :variant="BtnVariantsEnum.BARE"
                @click="emit('route', candidate)"
              >
                {{
                  t("hangarPlanner.addRoute", { ship: candidate.model.name })
                }}
              </Btn>
            </BtnDropdown>
          </span>
        </div>

        <div
          class="hangar-flow__action"
          :class="[
            `hangar-flow__action--${row.action.kind}`,
            { 'hangar-flow__action--decide': row.decisions },
          ]"
          role="cell"
        >
          <span class="hangar-flow__tag">
            <strong>
              <i v-if="row.action.icon" :class="row.action.icon" />
              {{ row.action.label }}
            </strong>
            <span v-if="row.action.detail">{{ row.action.detail }}</span>
          </span>
          <span
            v-if="row.vehicleId && row.decisions"
            class="hangar-flow__decisions"
          >
            <Btn
              v-for="decision in row.decisions"
              :key="decision"
              :size="BtnSizesEnum.XS"
              :variant="BtnVariantsEnum.BARE"
              :aria-label="t(`hangarPlanner.decisions.${decision}`)"
              :title="t(`hangarPlanner.decisions.${decision}`)"
              :data-test="`hangar-plan-decide-${decision}`"
              @click="decide(row, decision)"
            >
              <i
                :class="hangarFlowDecisionIcons[decision]"
                aria-hidden="true"
              />
            </Btn>
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
          <Btn
            v-if="row.slotAction?.kind === 'pick'"
            :size="BtnSizesEnum.XS"
            data-test="hangar-plan-flow-pick"
            @click="pick(row)"
          >
            <i class="fa-light fa-plus" aria-hidden="true" />
            {{ t("hangarPlanner.addShips") }}
          </Btn>
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

// A melted ship sits among the ships still being planned, so it reads as
// leaving: its card fades and its tag takes the colour of the fire.
.hangar-flow__row--melted {
  .hangar-flow__card:first-child {
    opacity: 0.55;

    .hangar-flow__image {
      filter: grayscale(1);
    }
  }

  .hangar-flow__action::before {
    border-top-color: var(--color-danger);
  }

  .hangar-flow__tag {
    border-color: var(--color-danger);

    strong,
    i {
      color: var(--color-danger);
    }
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

.hangar-flow__action--decide {
  flex-direction: column;
  gap: 4px;
  height: auto;
  min-height: 64px;

  &::before,
  &::after {
    display: none;
  }
}

.hangar-flow__action--pending .hangar-flow__tag {
  border-style: dashed;
}

.hangar-flow__action--change .hangar-flow__tag {
  border-color: var(--color-warning);

  strong {
    color: var(--color-warning);
  }
}

.hangar-flow__route-action {
  margin-left: auto;
}

.hangar-flow__card--none .hangar-flow__route-action {
  margin-left: 0;
}

.hangar-flow__decisions {
  display: flex;
  gap: 2px;
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

    &.hangar-flow__action--decide {
      flex-direction: row;
      align-items: center;
    }

    &::before,
    &::after {
      display: none;
    }
  }
}
</style>
