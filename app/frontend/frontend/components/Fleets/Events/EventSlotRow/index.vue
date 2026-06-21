<script lang="ts">
export default {
  name: "FleetEventsSlotRow",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import VehiclePicker from "@/frontend/components/Fleets/Events/VehiclePicker/index.vue";
import {
  type Fleet,
  type FleetEvent,
  type FleetEventExtended,
  type FleetEventShip,
  type FleetEventSignup,
  type FleetEventSlot,
  FleetEventSignupStatus,
  useSignupFleetEventSlot,
} from "@/services/fyApi";
import { vehicleMatchesShip } from "@/frontend/composables/useShipMatch";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  slotData: FleetEventSlot;
  ship?: FleetEventShip | null;
  currentUserId?: string;
  signupsLocked: boolean;
  // True when the event is in a state that accepts new signups (not draft,
  // not locked, not started, not past). Falls back to signupsLocked when
  // omitted for backwards compatibility.
  signupsOpen?: boolean;
  // Slot id where the current user is already signed up (anywhere in the event)
  ownActiveSlotId?: string | null;
  // Manager-only: needed to open the slot picker modal.
  isManager?: boolean;
  fleet?: Fleet;
  event?: FleetEvent | FleetEventExtended;
};

const props = withDefaults(defineProps<Props>(), {
  ship: null,
  currentUserId: undefined,
  signupsOpen: undefined,
  ownActiveSlotId: null,
  isManager: false,
  fleet: undefined,
  event: undefined,
});

const signupsAllowed = computed(() =>
  props.signupsOpen === undefined ? !props.signupsLocked : props.signupsOpen,
);

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const signupMutation = useSignupFleetEventSlot();

// Vehicle selection is only relevant when the slot is on a filter-mode ship
// (any ship matching the filter is acceptable). Specific-model ships and
// team-level slots have no vehicle choice to make.
const showVehiclePicker = computed(() => !!props.ship && !props.ship.model?.id);

const signupVehicleFitsHere = (signup: FleetEventSignup) =>
  vehicleMatchesShip(signup.vehicle, props.ship);

const extendedEvent = computed<FleetEventExtended | null>(() => {
  const e = props.event;
  if (e && "teams" in e) return e as FleetEventExtended;
  return null;
});

const canReassign = computed(
  () => props.isManager && !!props.fleet && !!extendedEvent.value,
);

const openReassign = (signup: FleetEventSignup) => {
  if (!props.fleet || !extendedEvent.value) return;
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/EventSlotPickerModal/index.vue"),
    props: {
      fleet: props.fleet,
      event: extendedEvent.value,
      signup,
      currentSlotId: props.slotData.id,
    },
  });
};

const otherSignups = computed<FleetEventSignup[]>(() => {
  return (props.slotData.signups ?? []).filter(
    (signup) => signup.user?.id !== props.currentUserId,
  );
});

// Managers see their own signup in the signup list too so they can use the
// reassign affordance on themselves. Regular members only see other members.
const visibleSignups = computed<FleetEventSignup[]>(() =>
  props.isManager
    ? (props.slotData.signups ?? []).filter((s) => s.status !== "withdrawn")
    : otherSignups.value,
);

const ownSignupHere = computed<FleetEventSignup | null>(() => {
  return (
    (props.slotData.signups ?? []).find(
      (signup) => signup.user?.id === props.currentUserId,
    ) ?? null
  );
});

const ownSignupElsewhere = computed(
  () => !!props.ownActiveSlotId && props.ownActiveSlotId !== props.slotData.id,
);

const slotTaken = computed(() => otherSignups.value.length > 0);

const canSignup = computed(
  () =>
    signupsAllowed.value &&
    !ownSignupHere.value &&
    !ownSignupElsewhere.value &&
    !slotTaken.value,
);

const blockedReason = computed(() => {
  if (!signupsAllowed.value) return t("labels.fleets.events.signupsLockedHint");
  if (ownSignupElsewhere.value)
    return t("labels.fleets.events.alreadySignedUpHint");
  if (slotTaken.value) return t("labels.fleets.events.slotTakenHint");
  return "";
});

const expanded = ref(false);
const notes = ref("");
const vehicleId = ref<string | null>(null);

const startSignup = () => {
  notes.value = "";
  vehicleId.value = null;
  expanded.value = true;
};

const cancelSignup = () => {
  expanded.value = false;
};

const submitSignup = async () => {
  try {
    await signupMutation.mutateAsync({
      id: props.slotData.id,
      data: {
        status: FleetEventSignupStatus.confirmed,
        notes: notes.value.trim() || undefined,
        vehicleId: vehicleId.value ?? undefined,
      },
    });
    displaySuccess({ text: t("messages.fleets.eventSignup.create.success") });
    expanded.value = false;
    comlink.emit("fleet-event-signup-changed");
  } catch {
    displayAlert({ text: t("messages.fleets.eventSignup.create.failure") });
  }
};
</script>

<template>
  <div
    class="event-slot-row"
    :class="{
      'event-slot-row--mine': !!ownSignupHere,
      'event-slot-row--expanded': expanded,
    }"
  >
    <header class="event-slot-row__head">
      <div class="event-slot-row__title">
        <strong>{{ slotData.title }}</strong>
        <span v-if="slotData.positionType" class="event-slot-row__type">
          {{ slotData.positionType }}
        </span>
      </div>
      <div class="event-slot-row__action">
        <span v-if="ownSignupHere" class="event-slot-row__here-badge">
          <i class="fa-light fa-check" />
          {{ t("labels.fleets.events.youAreHere") }}
        </span>
        <Btn
          v-else-if="!expanded"
          :size="BtnSizesEnum.SMALL"
          inline
          :disabled="!canSignup"
          :title="blockedReason"
          @click="startSignup"
        >
          <i class="fa-light fa-hand" />
          {{ t("actions.fleets.events.signup") }}
        </Btn>
      </div>
    </header>

    <p
      v-if="slotData.description"
      class="event-slot-row__description text-muted"
    >
      <i class="fa-light fa-circle-info" />
      <span>{{ slotData.description }}</span>
    </p>

    <ul v-if="visibleSignups.length" class="event-slot-row__signups">
      <li
        v-for="signup in visibleSignups"
        :key="signup.id"
        class="event-slot-row__signup"
      >
        <div class="event-slot-row__signup-line">
          <i
            class="fa-light"
            :class="
              signup.status === 'confirmed'
                ? 'fa-circle-check'
                : 'fa-circle-question'
            "
          />
          <span class="event-slot-row__signup-name">
            {{ signup.user?.username || "?" }}
          </span>
          <span class="event-slot-row__signup-status text-muted">
            {{ t(`labels.fleets.events.signupStatuses.${signup.status}`) }}
          </span>
          <span
            v-if="showVehiclePicker && signup.vehicle?.model?.name"
            class="event-slot-row__signup-vehicle text-muted"
          >
            · {{ signup.vehicle.model.name }}
          </span>
          <span
            v-if="showVehiclePicker && signupVehicleFitsHere(signup)"
            v-tooltip="t('labels.fleets.events.vehicleFitsHint')"
            class="event-slot-row__signup-fit"
          >
            <i class="fa-light fa-circle-check" />
          </span>
          <span
            v-else-if="showVehiclePicker && !signupVehicleFitsHere(signup)"
            v-tooltip="t('labels.fleets.events.vehicleMismatchHint')"
            class="event-slot-row__signup-warn"
          >
            <i class="fa-light fa-triangle-exclamation" />
          </span>
        </div>
        <p v-if="signup.notes" class="event-slot-row__signup-notes text-muted">
          <i class="fa-light fa-note-sticky" />
          <span>{{ signup.notes }}</span>
        </p>
        <div v-if="canReassign" class="event-slot-row__reassign">
          <Btn
            :size="BtnSizesEnum.SMALL"
            inline
            variant="link"
            @click="openReassign(signup)"
          >
            <i class="fa-light fa-arrow-right-arrow-left" />
            {{ t("actions.fleets.events.reassignSlot") }}
          </Btn>
        </div>
      </li>
    </ul>

    <div v-if="expanded" class="event-slot-row__form">
      <VehiclePicker
        v-if="showVehiclePicker"
        v-model="vehicleId"
        :required-ship="ship"
      />
      <FormTextarea
        v-model="notes"
        name="notes"
        :label="`${t('labels.fleets.events.notes')} (${t('labels.optional')})`"
      />
      <div class="event-slot-row__form-actions">
        <Btn
          :size="BtnSizesEnum.SMALL"
          inline
          :loading="signupMutation.isPending.value"
          @click="submitSignup"
        >
          <i class="fa-light fa-check" />
          {{ t("actions.fleets.events.signup") }}
        </Btn>
        <Btn
          :size="BtnSizesEnum.SMALL"
          inline
          variant="link"
          @click="cancelSignup"
        >
          {{ t("actions.cancel") }}
        </Btn>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.event-slot-row {
  background: rgba(255, 255, 255, 0.03);
  border-radius: 4px;
  padding: 0.55rem 0.75rem;
  border: 1px solid rgba(255, 255, 255, 0.05);
  transition: border-color 0.15s;
}
.event-slot-row--mine {
  border-color: var(--accent, #4aa);
  box-shadow: inset 0 0 0 1px var(--accent, #4aa);
}
.event-slot-row--expanded {
  border-color: rgba(255, 255, 255, 0.18);
}
.event-slot-row__head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.6rem;
  flex-wrap: wrap;
}
.event-slot-row__title {
  display: flex;
  flex-direction: column;
  gap: 0.1rem;
  min-width: 0;
  flex: 1;
}
.event-slot-row__type {
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-muted);
}
.event-slot-row__here-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  font-size: 0.78rem;
  padding: 0.2rem 0.5rem;
  border-radius: 999px;
  background: rgba(74, 170, 170, 0.18);
  color: var(--accent, #4aa);
  white-space: nowrap;
}
.event-slot-row__description {
  display: flex;
  gap: 0.4rem;
  font-size: 0.82rem;
  margin: 0.35rem 0 0;
  white-space: pre-wrap;

  i {
    margin-top: 0.2rem;
  }
}
.event-slot-row__signups {
  list-style: none;
  padding: 0;
  margin: 0.4rem 0 0;
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}
.event-slot-row__signup {
  display: flex;
  flex-direction: column;
  gap: 0.15rem;
}
.event-slot-row__signup-line {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  font-size: 0.85rem;
  flex-wrap: wrap;

  i {
    color: var(--text-muted);
  }
}
.event-slot-row__signup-name {
  min-width: 0;
  overflow-wrap: anywhere;
  font-weight: 500;
}
.event-slot-row__signup-status {
  font-size: 0.72rem;
}
.event-slot-row__signup-vehicle {
  font-size: 0.78rem;
}
.event-slot-row__signup-notes {
  display: flex;
  gap: 0.4rem;
  margin: 0;
  padding-left: 1.4rem;
  font-size: 0.8rem;
  white-space: pre-wrap;

  i {
    margin-top: 0.2rem;
    color: var(--text-muted);
  }
}
.event-slot-row__form {
  margin-top: 0.6rem;
  padding-top: 0.6rem;
  border-top: 1px dashed rgba(255, 255, 255, 0.1);
}
.event-slot-row__form-actions {
  display: flex;
  gap: 0.4rem;
}
.event-slot-row__signup-warn {
  color: var(--warning, #ff9800);
}
.event-slot-row__signup-fit {
  color: var(--success, #4caf50);
}
.event-slot-row__reassign {
  margin-top: 0.25rem;
}
</style>
