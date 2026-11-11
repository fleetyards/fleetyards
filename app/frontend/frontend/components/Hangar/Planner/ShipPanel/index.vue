<script lang="ts">
export default {
  name: "HangarPlannerShipPanel",
};
</script>

<script lang="ts" setup>
import CloseBtn from "@/shared/components/AppModal/CloseBtn/index.vue";
import StartView from "@/frontend/components/Hangar/Planner/ShipPanel/StartView/index.vue";
import EndView from "@/frontend/components/Hangar/Planner/ShipPanel/EndView/index.vue";
import SlotView from "@/frontend/components/Hangar/Planner/ShipPanel/SlotView/index.vue";
import RouteView from "@/frontend/components/Hangar/Planner/ShipPanel/RouteView/index.vue";
import type {
  HangarFlowTab,
  HangarFlowTarget,
} from "@/frontend/components/Hangar/Planner/HangarFlow/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";
import { type HangarPlanSlot, useHangarPlan } from "@/services/fyApi";

type Props = {
  planId: string;
  target: HangarFlowTarget;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  close: [];
}>();

const { t } = useI18n();
const comlink = useComlink();

// It slides over the page from the right, or up from the bottom as a sheet
// under the desktop layout, and leaves the page's own layout alone.
const sheet = useMobile();

const { data: plan } = useHangarPlan(() => props.planId);

const tab = ref<HangarFlowTab>(props.target.tab);
// A slot opened from a route's end, which the row itself does not offer.
const slotFromEnd = ref<HangarPlanSlot>();

const root = useTemplateRef<HTMLElement>("root");

const focus = () => root.value?.focus({ preventScroll: true });

// Opened for another row, it takes the keyboard again, so Escape still
// reaches it after the click on the flow.
watch(
  () => props.target,
  (target) => {
    tab.value = target.tab;
    slotFromEnd.value = undefined;
    void nextTick(focus);
  },
);

// The route as the plan has it now, rather than as the row was when clicked:
// a save elsewhere in the panel can have changed it since.
const liveRoute = computed(() => {
  const opened = props.target.route;
  if (!opened) return undefined;

  for (const slot of plan.value?.slots ?? []) {
    for (const candidate of slot.candidates) {
      const acquisition = candidate.acquisitions.find(
        (entry) => entry.id === opened.acquisition.id,
      );
      if (acquisition) return { candidate, acquisition };
    }
  }

  // Gone from the plan since, it has nothing left to edit.
  return plan.value ? undefined : opened;
});

const slot = computed(() => slotFromEnd.value ?? props.target.slot);

const tabs = computed(() => {
  const { start, end } = props.target;
  const route = liveRoute.value;

  return [
    start && {
      key: "start" as const,
      label: t("hangarPlanner.panel.tabs.start"),
      detail:
        start.acquisition?.startModel?.name ??
        t("hangarPlanner.pick.pickStart"),
    },
    route && {
      key: "route" as const,
      label: t("hangarPlanner.panel.tabs.route"),
      detail: t("hangarPlanner.panel.stepCount", {
        count: route.acquisition.steps.length,
      }),
    },
    end && {
      key: "end" as const,
      label: t("hangarPlanner.panel.tabs.end"),
      detail: route?.candidate.model.name ?? t("hangarPlanner.pick.pickEnd"),
    },
    slot.value &&
      (!end || slotFromEnd.value) && {
        key: "slot" as const,
        label: t("hangarPlanner.panel.tabs.slot"),
        detail: slot.value.label,
      },
  ].filter((entry) => !!entry);
});

const title = computed(() => {
  const { start, end } = props.target;
  const route = liveRoute.value;

  switch (tab.value) {
    case "start":
      return t("hangarPlanner.pick.startOf", {
        ship: start?.candidate?.model.name ?? start?.slot.label,
      });
    case "end":
      return t("hangarPlanner.pick.endOf", { ship: end?.startName });
    case "route":
      return t("hangarPlanner.editRoute", {
        ship: route?.candidate.model.name,
      });
    default:
      return slot.value?.label ?? "";
  }
});

const eyebrow = computed(() =>
  tab.value === "slot"
    ? t("hangarPlanner.editSlot")
    : (props.target.start?.slot.label ??
      props.target.end?.slot?.label ??
      props.target.slot?.label),
);

const routeView = useTemplateRef<{ dirty: boolean }>("routeView");

// Leaving a route with edits not saved asks first, the way a modal does.
const guard = (leave: () => void) => {
  if (tab.value !== "route" || !routeView.value?.dirty) {
    leave();
    return;
  }

  comlink.emit("show-confirm", {
    text: t("appModal.messages.confirm.dirty"),
    onConfirm: leave,
  });
};

const close = () => guard(() => emit("close"));

defineExpose({ guard });

const switchTo = (key: HangarFlowTab) => {
  if (key === tab.value) return;
  guard(() => {
    tab.value = key;
  });
};

const editSlot = (from: HangarPlanSlot) => {
  slotFromEnd.value = from;
  tab.value = "slot";
};

// Slot settings are a form of their own. On a phone the sheet steps aside
// for it, since a modal opens under it there.
const openSettings = (from: HangarPlanSlot) => {
  if (sheet.value) emit("close");

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/Planner/SlotModal/index.vue"),
    props: { planId: props.planId, slot: from },
  });
};

// The page under it stays put while the panel scrolls, as under the app's
// own off-canvas.
onMounted(() => {
  focus();
  document.body.classList.add("no-scroll");
});

onUnmounted(() => document.body.classList.remove("no-scroll"));

const onKeydown = (event: KeyboardEvent) => {
  if (event.key !== "Escape" || event.defaultPrevented) return;
  event.preventDefault();
  close();
};
</script>

<template>
  <div
    class="ship-panel__backdrop"
    :class="{ 'ship-panel__backdrop--sheet': sheet }"
    data-test="hangar-plan-panel-backdrop"
    @click="close"
  />
  <aside
    ref="root"
    class="ship-panel"
    :class="{ 'ship-panel--sheet': sheet }"
    :aria-label="title"
    tabindex="-1"
    data-test="hangar-plan-panel"
    @keydown="onKeydown"
  >
    <span v-if="sheet" class="ship-panel__grabber" aria-hidden="true" />
    <header class="ship-panel__header">
      <div class="ship-panel__heading">
        <span v-if="eyebrow" class="ship-panel__eyebrow">{{ eyebrow }}</span>
        <h2 class="ship-panel__title">{{ title }}</h2>
      </div>
      <CloseBtn data-test="hangar-plan-panel-close" @click="close" />
    </header>

    <div
      v-if="tabs.length > 1"
      class="ship-panel__tabs"
      role="tablist"
      :aria-label="title"
    >
      <button
        v-for="entry in tabs"
        :key="entry.key"
        type="button"
        role="tab"
        class="ship-panel__tab"
        :class="{ 'ship-panel__tab--active': entry.key === tab }"
        :aria-selected="entry.key === tab"
        :data-test="`hangar-plan-panel-tab-${entry.key}`"
        @click="switchTo(entry.key)"
      >
        <span class="ship-panel__tab-label">{{ entry.label }}</span>
        <span class="ship-panel__tab-detail">{{ entry.detail }}</span>
      </button>
    </div>

    <StartView
      v-if="tab === 'start' && target.start"
      :key="`start-${target.key}`"
      :plan-id="planId"
      v-bind="target.start"
      @done="emit('close')"
    />
    <EndView
      v-else-if="tab === 'end' && target.end"
      :key="`end-${target.key}`"
      :plan-id="planId"
      v-bind="target.end"
      @done="emit('close')"
      @edit-slot="editSlot"
    />
    <RouteView
      v-else-if="tab === 'route' && liveRoute"
      ref="routeView"
      :key="`route-${target.key}`"
      :plan-id="planId"
      :candidate="liveRoute.candidate"
      :acquisition="liveRoute.acquisition"
      @done="emit('close')"
    />
    <SlotView
      v-else-if="tab === 'slot' && slot"
      :key="`slot-${slot.id}`"
      :plan-id="planId"
      :slot="slot"
      @done="emit('close')"
      @settings="openSettings"
    />
  </aside>
</template>

<style lang="scss" scoped>
// Over the plan, under any modal it opens.
.ship-panel {
  position: fixed;
  top: 0;
  right: 0;
  bottom: 0;
  z-index: 1040;
  display: flex;
  flex-direction: column;
  width: min(860px, 58vw);
  border-left: 2px solid var(--color-edge);
  background: rgb(22 24 28 / 0.97);
  box-shadow: -18px 0 40px -20px rgb(0 0 0 / 0.9);
  outline: none;
  animation: ship-panel-in 0.2s ease-out;

  @media (prefers-reduced-motion: reduce) {
    animation: none;
  }
}

@keyframes ship-panel-in {
  from {
    transform: translateX(24px);
    opacity: 0;
  }
}

@keyframes ship-panel-up {
  from {
    transform: translateY(24px);
    opacity: 0;
  }
}

.ship-panel--sheet {
  top: 64px;
  animation-name: ship-panel-up;
  left: 0;
  z-index: 2010;
  width: auto;
  border-top: 2px solid var(--color-edge);
  border-left: 0;
  border-radius: 16px 16px 0 0;
}

// Lighter beside the panel than under a modal, so the row it is open for
// still reads at the page's left.
.ship-panel__backdrop {
  position: fixed;
  inset: 0;
  z-index: 1039;
  background: rgb(0 0 0 / 0.45);
}

.ship-panel__backdrop--sheet {
  z-index: 2009;
  background: rgb(0 0 0 / 0.6);
}

.ship-panel__grabber {
  align-self: center;
  width: 40px;
  height: 4px;
  margin-top: 8px;
  border-radius: 2px;
  background: var(--color-endcap);
}

.ship-panel__header {
  display: flex;
  gap: 16px;
  align-items: flex-start;
  justify-content: space-between;
  padding: 24px 28px 14px;

  .ship-panel--sheet & {
    padding: 10px 16px;
  }
}

.ship-panel__heading {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 0;
}

.ship-panel__eyebrow {
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 0.625rem;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--color-text-dim);
}

.ship-panel__title {
  margin: 0;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 1.375rem;
  font-weight: 400;
  line-height: 1.2;
  color: var(--color-lifted);

  .ship-panel--sheet & {
    font-size: 1.125rem;
  }
}

.ship-panel__tabs {
  display: flex;
  gap: 6px;
  margin: 0 28px 4px;
  padding: 4px;
  border-radius: 12px;
  background: var(--color-gray-black);

  .ship-panel--sheet & {
    margin: 0 16px 4px;
  }
}

.ship-panel__tab {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 1px;
  min-width: 0;
  min-height: 44px;
  padding: 6px 12px;
  border: 1px solid transparent;
  border-radius: 8px;
  background: transparent;
  color: var(--color-text);
  font: inherit;
  text-align: left;
  cursor: pointer;

  &:hover {
    background: var(--color-control);
  }

  &:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: 1px;
  }
}

.ship-panel__tab--active {
  border-color: var(--color-primary);
  background: var(--color-control);
}

.ship-panel__tab-label {
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 0.625rem;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--color-text-dim);
}

.ship-panel__tab-detail {
  overflow: hidden;
  font-weight: 600;
  white-space: nowrap;
  text-overflow: ellipsis;
  color: var(--color-lifted);
}
</style>
