<script lang="ts">
export default {
  name: "HangarPlannerReadiness",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type HangarPlanSlot,
  type HangarPlanSlotCost,
  HangarPlanSlotStateEnum,
} from "@/services/fyApi";

type Props = {
  slots: HangarPlanSlot[];
  costs?: HangarPlanSlotCost[];
};

const props = withDefaults(defineProps<Props>(), {
  costs: () => [],
});

const { t } = useI18n();

type Attention = {
  slot: HangarPlanSlot;
  icon: string;
  text: string;
};

const counts = computed(() => {
  let routed = 0;
  let pending = 0;
  let open = 0;

  props.slots.forEach((slot) => {
    if (slot.state === HangarPlanSlotStateEnum.OPEN) {
      open += slot.quantity;
      return;
    }

    if (slot.state === HangarPlanSlotStateEnum.UNDECIDED) {
      pending += slot.quantity;
      return;
    }

    const unresolved = unresolvedCount(slot);
    routed += slot.quantity - unresolved;
    pending += unresolved;
  });

  return { routed, pending, open, total: routed + pending + open };
});

const unresolvedCount = (slot: HangarPlanSlot) => {
  const cost = props.costs.find((entry) => entry.slotId === slot.id);
  if (cost) return cost.unresolvedCount;

  return Math.max(
    0,
    slot.quantity - (slot.candidates[0]?.acquisitions.length ?? 0),
  );
};

const attention = computed<Attention[]>(() =>
  props.slots.flatMap((slot) => {
    if (slot.state === HangarPlanSlotStateEnum.OPEN) {
      return [
        {
          slot,
          icon: "fa-light fa-circle-dashed",
          text: t("hangarPlanner.readiness.open", { slot: slot.label }),
        },
      ];
    }

    if (slot.state === HangarPlanSlotStateEnum.UNDECIDED) {
      return [
        {
          slot,
          icon: "fa-light fa-scale-balanced",
          text: t("hangarPlanner.readiness.undecided", { slot: slot.label }),
        },
      ];
    }

    const unresolved = unresolvedCount(slot);
    if (!unresolved) return [];

    return [
      {
        slot,
        icon: "fa-light fa-route",
        text: t("hangarPlanner.readiness.unresolved", {
          slot: slot.label,
          count: unresolved,
        }),
      },
    ];
  }),
);

const share = (value: number) =>
  counts.value.total ? `${(value / counts.value.total) * 100}%` : "0%";

const focusSlot = (slot: HangarPlanSlot) => {
  const element = document.getElementById(`hangar-plan-slot-${slot.id}`);
  if (!element) return;

  element.scrollIntoView({ behavior: "smooth", block: "start" });
  element.focus({ preventScroll: true });
};
</script>

<template>
  <div
    v-if="counts.total"
    class="plan-readiness"
    data-test="hangar-plan-readiness"
  >
    <div class="plan-readiness__progress">
      <div class="plan-readiness__label">
        <strong>
          {{
            t("hangarPlanner.readiness.routed", {
              routed: counts.routed,
              count: counts.total,
            })
          }}
        </strong>
      </div>
      <div
        class="plan-readiness__track"
        role="progressbar"
        :aria-valuenow="counts.routed"
        aria-valuemin="0"
        :aria-valuemax="counts.total"
        :aria-label="t('hangarPlanner.routes')"
      >
        <span
          class="plan-readiness__part plan-readiness__part--routed"
          :style="{ width: share(counts.routed) }"
        />
        <span
          class="plan-readiness__part plan-readiness__part--pending"
          :style="{ width: share(counts.pending) }"
        />
      </div>
    </div>
    <ul v-if="attention.length" class="plan-readiness__issues">
      <li v-for="entry in attention" :key="entry.slot.id">
        <Btn
          :size="BtnSizesEnum.SM"
          data-test="hangar-plan-readiness-issue"
          @click="focusSlot(entry.slot)"
        >
          <i :class="entry.icon" class="plan-readiness__icon" />
          {{ entry.text }}
        </Btn>
      </li>
    </ul>
  </div>
</template>

<style lang="scss" scoped>
.plan-readiness {
  display: flex;
  flex-wrap: wrap;
  gap: 12px 24px;
  align-items: center;
  margin: 16px 0;
  padding: 14px 18px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
  background: var(--color-surface);
}

.plan-readiness__progress {
  display: flex;
  flex: 1 1 260px;
  flex-direction: column;
  gap: 8px;
  min-width: 0;
}

.plan-readiness__label strong {
  font-weight: 600;
  color: var(--color-lifted);
}

.plan-readiness__track {
  display: flex;
  gap: 3px;
  height: 6px;
  overflow: hidden;
  border-radius: 3px;
  background: var(--color-gray-black);
}

.plan-readiness__part {
  border-radius: 3px;
  transition: width 0.3s ease;
}

.plan-readiness__part--routed {
  background: var(--color-primary);
}

.plan-readiness__part--pending {
  background: var(--color-warning);
}

.plan-readiness__issues {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.plan-readiness__icon {
  color: var(--color-warning);
}
</style>
