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
  type FleetEventShip,
  type FleetEventSignup,
  type FleetEventSlot,
  FleetEventSignupStatus,
  useSignupFleetEventSlot,
  useAssignFleetEventSignup,
} from "@/services/fyApi";
import { vehicleMatchesShip } from "@/frontend/composables/useShipMatch";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type SlotContext = {
  slot: FleetEventSlot;
  teamTitle: string;
  shipTitle?: string;
  ship?: FleetEventShip | null;
};

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
  // Manager-only: list of all event slots for reassign action.
  isManager?: boolean;
  availableSlots?: SlotContext[];
};

const props = withDefaults(defineProps<Props>(), {
  ship: null,
  currentUserId: undefined,
  signupsOpen: undefined,
  ownActiveSlotId: null,
  isManager: false,
  availableSlots: () => [],
});

const signupsAllowed = computed(() =>
  props.signupsOpen === undefined ? !props.signupsLocked : props.signupsOpen,
);

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const signupMutation = useSignupFleetEventSlot();
const assignMutation = useAssignFleetEventSignup();
const reassigningId = ref<string | null>(null);

const slotIsTaken = (slot: FleetEventSlot, signup: FleetEventSignup) =>
  (slot.signups ?? []).some(
    (s) => s.status !== "withdrawn" && s.id !== signup.id,
  );

// Vehicle selection is only relevant when the slot is on a filter-mode ship
// (any ship matching the filter is acceptable). Specific-model ships and
// team-level slots have no vehicle choice to make.
const showVehiclePicker = computed(() => !!props.ship && !props.ship.model?.id);

const slotLabel = (ctx: SlotContext) => {
  const parts = [ctx.teamTitle];
  if (ctx.shipTitle) parts.push(ctx.shipTitle);
  parts.push(ctx.slot.title);
  return parts.join(" · ");
};

const signupVehicleFitsHere = (signup: FleetEventSignup) =>
  vehicleMatchesShip(signup.vehicle, props.ship);

const reassign = async (signup: FleetEventSignup, slotId: string) => {
  if (slotId === props.slotData.id) return;
  reassigningId.value = signup.id;
  try {
    await assignMutation.mutateAsync({
      id: signup.id,
      data: { fleetEventSlotId: slotId, status: "confirmed" },
    });
    displaySuccess({ text: t("messages.fleets.eventSignup.update.success") });
    comlink.emit("fleet-event-signup-changed");
  } catch {
    displayAlert({ text: t("messages.fleets.eventSignup.update.failure") });
  } finally {
    reassigningId.value = null;
  }
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
        <details
          v-if="isManager && availableSlots.length"
          class="event-slot-row__reassign"
        >
          <summary class="event-slot-row__reassign-toggle">
            <i class="fa-light fa-arrow-right-arrow-left" />
            {{ t("actions.fleets.events.reassignSlot") }}
          </summary>
          <ul class="event-slot-row__reassign-slots">
            <li
              v-for="ctx in availableSlots"
              :key="ctx.slot.id"
              class="event-slot-row__reassign-slot"
            >
              <Btn
                :size="BtnSizesEnum.SMALL"
                inline
                variant="link"
                :disabled="
                  ctx.slot.id === slotData.id ||
                  slotIsTaken(ctx.slot, signup) ||
                  reassigningId === signup.id
                "
                :title="
                  slotIsTaken(ctx.slot, signup)
                    ? t('labels.fleets.events.slotTakenHint')
                    : ''
                "
                @click="reassign(signup, ctx.slot.id)"
              >
                <span class="event-slot-row__reassign-label">
                  {{ slotLabel(ctx) }}
                </span>
                <span
                  v-if="vehicleMatchesShip(signup.vehicle, ctx.ship)"
                  class="event-slot-row__reassign-fit"
                >
                  <i class="fa-light fa-circle-check" />
                </span>
                <span
                  v-if="slotIsTaken(ctx.slot, signup)"
                  class="event-slot-row__reassign-taken"
                >
                  {{ t("labels.fleets.events.taken") }}
                </span>
              </Btn>
            </li>
          </ul>
        </details>
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
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  font-size: 0.85rem;

  i {
    color: var(--text-muted);
  }
}
.event-slot-row__signup-name {
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
.event-slot-row__reassign-toggle {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-size: 0.78rem;
  cursor: pointer;
  padding: 0.2rem 0.55rem;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 4px;
  list-style: none;

  &::-webkit-details-marker {
    display: none;
  }

  &:hover {
    border-color: rgba(255, 255, 255, 0.3);
  }
}
.event-slot-row__reassign-slots {
  list-style: none;
  margin: 0.3rem 0 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.15rem;
  max-height: 220px;
  overflow-y: auto;
}
.event-slot-row__reassign-slot {
  display: flex;
}
.event-slot-row__reassign-label {
  text-align: left;
  font-size: 0.82rem;
}
.event-slot-row__reassign-fit {
  margin-left: 0.4rem;
  color: var(--success, #4caf50);
}
.event-slot-row__reassign-taken {
  margin-left: 0.4rem;
  font-size: 0.7rem;
  color: var(--text-muted);
}
</style>
