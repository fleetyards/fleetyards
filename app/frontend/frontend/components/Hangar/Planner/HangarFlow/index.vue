<script lang="ts">
export default {
  name: "HangarPlannerHangarFlow",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { canEnter, canLeave } from "@/frontend/components/Hangar/Planner/reach";
import {
  type HangarFlowDecision,
  type HangarFlowEnd,
  type HangarFlowStart,
  hangarFlowDecisionIcons,
} from "@/frontend/components/Hangar/Planner/HangarFlow/types";
import { useI18n } from "@/shared/composables/useI18n";
import fallbackImage from "@/images/fallback/store_image.webp";
import {
  type HangarPlan,
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
  type HangarPlanComparison,
  type HangarPlanVehicleStatus,
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
  start: [start: HangarFlowStart];
  end: [end: HangarFlowEnd];
  pick: [slot: HangarPlanSlot];
  edit: [slot: HangarPlanSlot];
}>();

const { t } = useI18n();
const { money, range } = usePlanMoney();

type Card = {
  title: string;
  // Every ship the card stands for, where the title runs them together.
  ships?: string[];
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
  // A hangar ship the plan has not settled, with the ways left to settle it
  // besides picking where it ends up.
  vehicleId?: string;
  decisions?: HangarFlowDecision[];
  // What the left card picks a start for.
  start?: HangarFlowStart;
  // What the right card picks an end ship for.
  end?: HangarFlowEnd;
  // The route the middle plans or edits.
  route?: {
    candidate: HangarPlanCandidate;
    acquisition?: HangarPlanAcquisition;
  };
  // Both ends picked, but no upgrade leads from one to the other, so the
  // middle asks for another start instead.
  restart?: boolean;
  // The slot the right card opens where it picks no end: one still choosing
  // its ship, or one whose units have no start yet.
  slot?: HangarPlanSlot;
  // An empty slot, which the right card fills with ships to choose from.
  pickSlot?: HangarPlanSlot;
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

type PlannedRoute = (typeof routes.value)[number];

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

const slotCard = (route: PlannedRoute): Card => ({
  title: route.model.name,
  sub: slotSub(route.slot, route.index),
  model: route.model,
  pill: route.acquisition.routeComplete ? decidedPill.value : undefined,
  tone: route.acquisition.routeComplete ? undefined : "warning",
});

const routeTarget = (route: PlannedRoute) => ({
  candidate: route.candidate,
  acquisition: route.acquisition,
});

// RSI sells no upgrade into or out of some ships, so a start elsewhere can
// never become them.
const routable = (route: PlannedRoute) =>
  canLeave(route.acquisition.startModel) && canEnter(route.model);

const unroutedAction = (route: PlannedRoute) =>
  routable(route)
    ? {
        kind: "unrouted",
        icon: "fa-light fa-route",
        label: t("hangarPlanner.comparison.flow.planRoute"),
        detail: t("hangarPlanner.comparison.flow.notCounted"),
      }
    : {
        kind: "unrouted",
        icon: "fa-light fa-ban",
        label: t("hangarPlanner.comparison.flow.noUpgrade"),
        detail: t("hangarPlanner.comparison.flow.pickOtherStart"),
      };

// Where the middle leads for a planned route: the route itself, or another
// start when none can be planned.
const middle = (route: PlannedRoute) =>
  route.acquisition.routeComplete || routable(route)
    ? { route: routeTarget(route) }
    : { restart: true };

const routedAction = (route: PlannedRoute) => {
  const steps = route.acquisition.steps.length;

  return {
    kind: steps ? "upgraded" : "kept",
    icon: steps ? "fa-light fa-arrow-up-right" : undefined,
    label: steps
      ? t("hangarPlanner.vehicleStatuses.upgraded")
      : t("hangarPlanner.vehicleStatuses.kept"),
    detail: steps
      ? t("hangarPlanner.comparison.flow.steps", {
          count: steps,
          price: money(routeCost(route.acquisition)),
        })
      : money(0),
  };
};

// A hangar ship with a route: it starts the route on the left and ends in its
// slot on the right, and either end can be picked again.
const routedShipRow = (
  entry: HangarPlanVehicleStatus,
  route: PlannedRoute,
): Row => {
  const unrouted = !route.acquisition.routeComplete;
  const upgraded = route.acquisition.steps.length > 0;
  const left = hangarCard(entry.name, entry.model);

  return {
    key: entry.vehicleId,
    group: unrouted || upgraded ? "ships" : "kept",
    order: shipOrder(entry.vehicleId),
    testId: unrouted
      ? "hangar-plan-vehicle-unrouted"
      : "hangar-plan-vehicle-status",
    left,
    action: unrouted ? unroutedAction(route) : routedAction(route),
    right: slotCard(route),
    start: { slot: route.slot, ...routeTarget(route) },
    end: {
      startName: left.title,
      startModel: entry.model,
      vehicleId: entry.vehicleId,
      acquisition: route.acquisition,
      slot: route.slot,
    },
    ...middle(route),
  };
};

const meltedRow = (entry: HangarPlanVehicleStatus): Row => {
  const melt = props.plan.melts.find(
    (candidate) => candidate.vehicleId === entry.vehicleId,
  );

  return {
    key: entry.vehicleId,
    group: "ships",
    order: shipOrder(entry.vehicleId),
    testId: "hangar-plan-vehicle-status",
    left: hangarCard(entry.name, entry.model),
    action: {
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
    },
    rightNone: t("hangarPlanner.comparison.leaves"),
  };
};

const shipRows = computed<Row[]>(() =>
  props.comparison.vehicles.flatMap((entry): Row[] => {
    const left = hangarCard(entry.name, entry.model);
    const route = routes.value.find(
      (candidate) => candidate.acquisition.sourceVehicleId === entry.vehicleId,
    );
    const end: HangarFlowEnd = {
      startName: left.title,
      startModel: entry.model,
      vehicleId: entry.vehicleId,
    };
    const base = {
      key: entry.vehicleId,
      order: shipOrder(entry.vehicleId),
      left,
      vehicleId: entry.vehicleId,
    };

    switch (entry.status) {
      case HangarPlanVehicleStatusEnum.MELTED:
        return [meltedRow(entry)];
      case HangarPlanVehicleStatusEnum.KEPT:
      case HangarPlanVehicleStatusEnum.UPGRADED:
      case HangarPlanVehicleStatusEnum.UNROUTED:
        if (route) return [routedShipRow(entry, route)];

        // Kept without a slot: the plan only noted the decision.
        return [
          {
            ...base,
            group: "kept",
            testId: "hangar-plan-vehicle-status",
            action: {
              kind: "kept",
              label: t("hangarPlanner.vehicleStatuses.kept"),
              detail: money(0),
            },
            right: { ...left, sub: t("hangarPlanner.pick.same") },
            end,
          },
        ];
      case HangarPlanVehicleStatusEnum.PENDING:
      case HangarPlanVehicleStatusEnum.CHANGE: {
        const change = entry.status === HangarPlanVehicleStatusEnum.CHANGE;

        return [
          {
            ...base,
            group: "ships",
            testId: "hangar-plan-vehicle-review",
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
            ...(change && !canLeave(entry.model)
              ? {
                  // Nothing can be upgraded out of it, so changing it means
                  // melting it.
                  rightNone: t("hangarPlanner.pick.onlyMelt"),
                  decisions: ["melt", "pending"] as HangarFlowDecision[],
                }
              : {
                  rightNone: t("hangarPlanner.pick.pickEnd"),
                  decisions: [
                    "melt",
                    change ? "pending" : "change",
                  ] as HangarFlowDecision[],
                  end,
                }),
          },
        ];
      }
      default:
        return [
          {
            ...base,
            group: "unassigned",
            testId: "hangar-plan-vehicle-status",
            action: {
              kind: "unassigned",
              label: t("hangarPlanner.vehicleStatuses.unassigned"),
            },
            rightNone: t("hangarPlanner.pick.pickEnd"),
            decisions: ["melt", "change"],
            end,
          },
        ];
    }
  }),
);

const slotCost = (slot: HangarPlanSlot) =>
  props.summary?.slots.find((cost) => cost.slotId === slot.id);

const neededRows = computed<Row[]>(() => {
  const bought = routes.value
    .filter(
      (route) => route.acquisition.startKind !== HangarPlanStartKindEnum.OWNED,
    )
    .map((route): Row => {
      const { acquisition } = route;
      const left: Card = {
        title: acquisition.startModel.name,
        sub: t(`hangarPlanner.startKinds.${acquisition.startKind}`),
        model: acquisition.startModel,
      };

      return {
        key: acquisition.id,
        group: "slots",
        order: slotOrder(route.slot.id) + route.index,
        testId: acquisition.routeComplete
          ? "hangar-plan-flow-purchase"
          : "hangar-plan-flow-unrouted",
        left,
        action: acquisition.routeComplete
          ? {
              kind: acquisition.steps.length ? "upgraded" : "buy",
              icon: "fa-light fa-cart-shopping",
              label: acquisition.steps.length
                ? t("hangarPlanner.comparison.flow.steps", {
                    count: acquisition.steps.length,
                    price: money(routeCost(acquisition)),
                  })
                : t(`hangarPlanner.startKinds.${acquisition.startKind}`),
              detail: acquisition.steps.length
                ? undefined
                : money(routeCost(acquisition)),
            }
          : unroutedAction(route),
        right: slotCard(route),
        start: { slot: route.slot, ...routeTarget(route) },
        end: {
          startName: left.title,
          startModel: acquisition.startModel,
          acquisition,
          slot: route.slot,
        },
        ...middle(route),
      };
    });

  const gaps = props.comparison.gaps.flatMap((gap): Row[] => {
    const slot = props.plan.slots.find((entry) => entry.id === gap.slotId);
    const candidate = slot?.candidates[0];
    if (!slot || !candidate) return [];

    return [
      {
        key: `gap-${gap.slotId}`,
        group: "slots",
        order: slotOrder(gap.slotId) + SLOT_ROWS - 1,
        testId: "hangar-plan-gap",
        leftNone: t("hangarPlanner.pick.pickStart"),
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
          tone: "warning",
        },
        start: { slot, candidate },
        route: { candidate },
        slot,
      },
    ];
  });

  const undecided = props.plan.slots
    .filter((slot) => slot.state === HangarPlanSlotStateEnum.UNDECIDED)
    .map((slot): Row => {
      const cost = slotCost(slot);

      return {
        key: `undecided-${slot.id}`,
        group: "slots",
        order: slotOrder(slot.id),
        testId: "hangar-plan-flow-undecided",
        leftNone: t("hangarPlanner.pick.pickStart"),
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
          ships: slot.candidates.map((candidate) => candidate.model.name),
          sub: slot.label,
          model: slot.candidates[0]?.model,
          pill: {
            variant: PillVariantsEnum.WARNING,
            label: t("hangarPlanner.states.undecided"),
          },
          tone: "warning",
        },
        start: { slot },
        slot,
      };
    });

  const open = props.plan.slots
    .filter((slot) => slot.state === HangarPlanSlotStateEnum.OPEN)
    .map((slot): Row => ({
      key: `open-${slot.id}`,
      group: "slots",
      order: slotOrder(slot.id),
      testId: "hangar-plan-flow-open",
      leftNone: t("hangarPlanner.comparison.notOwned"),
      action: {
        kind: "open",
        label: t("hangarPlanner.states.open"),
        detail: t("hangarPlanner.comparison.flow.noShip"),
      },
      rightNone: `${slot.label} · ${t("hangarPlanner.comparison.flow.noShip")}`,
      pickSlot: slot,
      slot,
    }));

  return [...bought, ...gaps, ...undecided, ...open];
});

// The plan's slots come first, so one just added shows above the ships; then
// the ships being worked on. Ships kept as they are, and those the plan has no
// use for, wait folded.
const groupOrder: RowGroup[] = ["slots", "ships", "kept", "unassigned"];

const folded: RowGroup[] = ["kept", "unassigned"];

const groups = computed<Group[]>(() => {
  const rows = [...shipRows.value, ...neededRows.value];

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

const pickStart = (row: Row) => {
  if (row.start) emit("start", row.start);
};

const pickEnd = (row: Row) => {
  if (row.end) {
    emit("end", row.end);
  } else if (row.pickSlot) {
    emit("pick", row.pickSlot);
  } else if (row.slot) {
    emit("edit", row.slot);
  }
};

const openMiddle = (row: Row) => {
  if (row.route) {
    emit("route", row.route.candidate, row.route.acquisition);
  } else if (row.restart) {
    pickStart(row);
  }
};

const middleLabel = (row: Row) => {
  if (row.restart && row.start) {
    return t("hangarPlanner.pick.startOf", {
      ship: row.start.candidate?.model.name ?? row.start.slot.label,
    });
  }
  if (!row.route) return undefined;

  return t(
    row.route.acquisition
      ? "hangarPlanner.editRoute"
      : "hangarPlanner.addRoute",
    { ship: row.route.candidate.model.name },
  );
};

const rightLabel = (row: Row) =>
  row.end
    ? t("hangarPlanner.pick.endOf", { ship: row.end.startName })
    : row.slot
      ? t("hangarPlanner.editSlotOf", { slot: row.slot.label })
      : undefined;

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
            'hangar-flow__card--action': row.start,
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
              <button
                v-if="row.start"
                type="button"
                class="hangar-flow__card-action"
                :aria-label="
                  t('hangarPlanner.pick.startOf', {
                    ship:
                      row.start.candidate?.model.name ?? row.start.slot.label,
                  })
                "
                data-test="hangar-plan-flow-pick-start"
                @click="pickStart(row)"
              >
                {{ row.left.title }}
              </button>
              <strong v-else>{{ row.left.title }}</strong>
              <span v-if="row.left.sub" class="hangar-flow__muted">
                {{ row.left.sub }}
              </span>
            </span>
          </template>
          <button
            v-else-if="row.start"
            type="button"
            class="hangar-flow__card-action hangar-flow__card-action--none"
            :aria-label="
              t('hangarPlanner.pick.startOf', {
                ship: row.start.candidate?.model.name ?? row.start.slot.label,
              })
            "
            data-test="hangar-plan-flow-pick-start"
            @click="pickStart(row)"
          >
            <i class="fa-light fa-plus" aria-hidden="true" />
            {{ row.leftNone }}
          </button>
          <template v-else>{{ row.leftNone }}</template>
        </div>

        <div
          class="hangar-flow__action"
          :class="[
            `hangar-flow__action--${row.action.kind}`,
            { 'hangar-flow__action--decide': row.decisions },
          ]"
          role="cell"
        >
          <component
            :is="middleLabel(row) ? 'button' : 'span'"
            :type="middleLabel(row) ? 'button' : undefined"
            class="hangar-flow__tag"
            :class="{ 'hangar-flow__tag--button': middleLabel(row) }"
            :aria-label="middleLabel(row)"
            :data-test="middleLabel(row) ? 'hangar-plan-flow-route' : undefined"
            @click="openMiddle(row)"
          >
            <strong>
              <i v-if="row.action.icon" :class="row.action.icon" />
              {{ row.action.label }}
            </strong>
            <span v-if="row.action.detail">{{ row.action.detail }}</span>
          </component>
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
          :class="{
            'hangar-flow__card--warning': row.right.tone,
            'hangar-flow__card--action': rightLabel(row),
          }"
          role="cell"
        >
          <img
            :src="imageOf(row.right.model)"
            alt=""
            class="hangar-flow__image"
            loading="lazy"
          />
          <span class="hangar-flow__text">
            <button
              v-if="rightLabel(row)"
              type="button"
              v-tooltip="{
                content: (row.right.ships ?? [row.right.title]).join('\n'),
                multiline: true,
                preserveLineBreaks: true,
              }"
              class="hangar-flow__card-action"
              :aria-label="rightLabel(row)"
              :data-test="
                row.end
                  ? 'hangar-plan-flow-pick-end'
                  : 'hangar-plan-flow-edit-slot'
              "
              @click="pickEnd(row)"
            >
              {{ row.right.title }}
            </button>
            <strong v-else>{{ row.right.title }}</strong>
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
          :class="{ 'hangar-flow__card--action': row.end }"
          role="cell"
        >
          <button
            v-if="row.end"
            type="button"
            class="hangar-flow__card-action hangar-flow__card-action--none"
            :aria-label="rightLabel(row)"
            data-test="hangar-plan-flow-pick-end"
            @click="pickEnd(row)"
          >
            <i class="fa-light fa-plus" aria-hidden="true" />
            {{ row.rightNone }}
          </button>
          <template v-else>
            <button
              v-if="row.slot"
              type="button"
              class="hangar-flow__slot-edit"
              :aria-label="
                t('hangarPlanner.editSlotOf', { slot: row.slot.label })
              "
              data-test="hangar-plan-flow-edit-slot"
              @click="emit('edit', row.slot)"
            >
              {{ row.rightNone }}
              <i class="fa-light fa-pen" aria-hidden="true" />
            </button>
            <template v-else>{{ row.rightNone }}</template>
            <Btn
              v-if="row.pickSlot"
              :size="BtnSizesEnum.XS"
              data-test="hangar-plan-flow-pick"
              @click="pickEnd(row)"
            >
              <i class="fa-light fa-plus" aria-hidden="true" />
              {{ t("hangarPlanner.addShips") }}
            </Btn>
          </template>
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

// Both ends are picked but nothing leads from one to the other yet.
.hangar-flow__action--unrouted {
  &::before {
    border-top: 1px dashed var(--color-warning);
  }

  &::after {
    border-left-color: var(--color-warning);
  }

  .hangar-flow__tag {
    border-style: dashed;
    border-color: var(--color-warning);

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

// The whole card opens its slot: the title's button stretches over it.
.hangar-flow__card--action {
  position: relative;

  &:hover {
    border-color: var(--color-edge-strong);
    background: var(--color-control-hover);
  }

  &:has(.hangar-flow__card-action:focus-visible) {
    outline: 2px solid var(--color-primary);
    outline-offset: 1px;
  }
}

.hangar-flow__card-action {
  overflow: hidden;
  padding: 0;
  border: 0;
  background: transparent;
  font: inherit;
  font-weight: 700;
  text-align: left;
  text-overflow: ellipsis;
  white-space: nowrap;
  color: var(--color-lifted);
  cursor: pointer;

  &::after {
    content: "";
    position: absolute;
    inset: 0;
    border-radius: inherit;
  }

  &:focus-visible {
    outline: none;
  }
}

.hangar-flow__card-action--none {
  display: inline-flex;
  gap: 6px;
  align-items: center;
  font-weight: 400;
  color: var(--color-text-dim);

  i {
    color: var(--color-primary);
  }
}

.hangar-flow__slot-edit {
  display: inline-flex;
  gap: 6px;
  align-items: center;
  padding: 4px 6px;
  border: 0;
  border-radius: 6px;
  background: transparent;
  font: inherit;
  color: inherit;
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

.hangar-flow__tag--button {
  font: inherit;
  font-size: 0.75rem;
  color: inherit;
  cursor: pointer;

  &:hover {
    border-color: var(--color-edge-strong);
    background: var(--color-control-hover);
  }

  &:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: 1px;
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
