<script lang="ts">
export default {
  name: "FleetSquadronSlotCandidates",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { type LineupScope } from "@/frontend/components/Fleets/Missions/useLineupApi";
import {
  type FleetSquadronSlotCandidate,
  type FleetSquadronVehicle,
} from "@/services/fyApi";

type Props = {
  slot: {
    id: string;
    title: string;
    candidates?: FleetSquadronSlotCandidate[];
  };
  scope?: LineupScope;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  scope: undefined,
  editable: false,
});

const { t } = useI18n();
const comlink = useComlink();

const candidates = computed(() => props.slot.candidates ?? []);

const vehicleLabel = (vehicle?: FleetSquadronVehicle | null) =>
  vehicle ? vehicle.name || vehicle.model?.name : undefined;

const openEditor = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SlotCandidatesModal/index.vue"),
    props: { slot: props.slot, scope: props.scope },
  });
};
</script>

<template>
  <div class="slot-candidates" data-test="slot-candidates">
    <ol v-if="candidates.length" class="slot-candidates__list">
      <li
        v-for="(candidate, index) in candidates"
        :key="candidate.id"
        class="slot-candidates__item"
        :class="{
          'slot-candidates__item--primary': index === 0,
          'slot-candidates__item--passed': !!candidate.passedAt,
        }"
      >
        <span class="slot-candidates__name">{{ candidate.username }}</span>
        <span
          v-if="vehicleLabel(candidate.vehicle)"
          class="slot-candidates__ship"
        >
          {{ vehicleLabel(candidate.vehicle) }}
        </span>
      </li>
    </ol>
    <span v-else class="slot-candidates__empty">
      {{ t("labels.fleet.squadrons.flights.noCandidates") }}
    </span>
    <Btn
      v-if="editable"
      :size="BtnSizesEnum.SM"
      :variant="BtnVariantsEnum.BARE"
      :aria-label="t('actions.fleet.squadrons.flights.editCandidates')"
      data-test="slot-candidates-edit"
      @click="openEditor"
    >
      <i class="fa-duotone fa-user-gear" />
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
.slot-candidates {
  display: flex;
  flex-basis: 100%;
  align-items: center;
  gap: 6px;
  padding-left: 22px;
  font-size: 0.75rem;
  color: var(--color-muted, #7a8288);
}

.slot-candidates__list {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 10px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.slot-candidates__item {
  display: inline-flex;
  gap: 4px;

  &:not(:first-child)::before {
    content: "›";
    margin-right: 6px;
  }
}

.slot-candidates__item--primary .slot-candidates__name {
  color: var(--color-text, inherit);
  font-weight: 600;
}

.slot-candidates__item--passed {
  text-decoration: line-through;
}

.slot-candidates__ship {
  font-style: italic;
}

.slot-candidates__empty {
  font-style: italic;
}
</style>
