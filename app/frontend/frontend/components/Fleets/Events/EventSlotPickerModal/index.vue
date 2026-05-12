<script lang="ts">
export default {
  name: "FleetEventsSlotPickerModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type Fleet,
  type FleetEventExtended,
  type FleetEventShip,
  type FleetEventSignup,
  type FleetEventSlot,
  type FleetEventTeam,
  useAssignFleetEventSignup,
} from "@/services/fyApi";
import { vehicleMatchesShip } from "@/frontend/composables/useShipMatch";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  fleet: Fleet;
  event: FleetEventExtended;
  signup: FleetEventSignup;
  currentSlotId?: string | null;
};

const props = withDefaults(defineProps<Props>(), {
  currentSlotId: null,
});

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const assignMutation = useAssignFleetEventSignup();

const mode = computed<"assign" | "reassign">(() =>
  props.currentSlotId ? "reassign" : "assign",
);

const slotTakenBy = (slot: FleetEventSlot): FleetEventSignup | null => {
  return (
    (slot.signups ?? []).find(
      (s) => s.status !== "withdrawn" && s.id !== props.signup.id,
    ) ?? null
  );
};

const submit = async (slot: FleetEventSlot) => {
  if (slot.id === props.currentSlotId) return;
  try {
    await assignMutation.mutateAsync({
      id: props.signup.id,
      data: { fleetEventSlotId: slot.id, status: "confirmed" },
    });
    displaySuccess({ text: t("messages.fleets.eventSignup.update.success") });
    comlink.emit("fleet-event-signup-changed");
    comlink.emit("close-modal");
  } catch {
    displayAlert({ text: t("messages.fleets.eventSignup.update.failure") });
  }
};

const teams = computed<FleetEventTeam[]>(
  () => (props.event.teams ?? []) as FleetEventTeam[],
);
</script>

<template>
  <Modal
    :title="
      mode === 'reassign'
        ? t('headlines.fleets.events.reassignSlotFor', {
            username: signup.user?.username || '?',
          })
        : t('headlines.fleets.events.assignSlotFor', {
            username: signup.user?.username || '?',
          })
    "
  >
    <p class="text-muted small">
      {{ t("labels.fleets.events.slotPickerHint") }}
    </p>

    <div class="slot-picker">
      <section v-for="team in teams" :key="team.id" class="slot-picker__team">
        <header class="slot-picker__team-head">
          <i class="fa-light fa-users" />
          <strong>{{ team.title }}</strong>
        </header>

        <ul v-if="team.slots?.length" class="slot-picker__slots">
          <li
            v-for="slot in (team.slots ?? []) as FleetEventSlot[]"
            :key="slot.id"
            class="slot-picker__slot"
          >
            <Btn
              :size="BtnSizesEnum.SMALL"
              inline
              variant="link"
              :disabled="
                slot.id === currentSlotId ||
                !!slotTakenBy(slot) ||
                assignMutation.isPending.value
              "
              :title="
                slot.id === currentSlotId
                  ? t('labels.fleets.events.currentSlotHint')
                  : slotTakenBy(slot)
                    ? t('labels.fleets.events.slotTakenHint')
                    : ''
              "
              @click="submit(slot)"
            >
              <span class="slot-picker__slot-label">{{ slot.title }}</span>
              <span
                v-if="slot.positionType"
                class="slot-picker__slot-type text-muted"
              >
                {{ slot.positionType }}
              </span>
              <span
                v-if="slot.id === currentSlotId"
                class="slot-picker__slot-badge slot-picker__slot-badge--current"
              >
                {{ t("labels.fleets.events.currentSlot") }}
              </span>
              <span
                v-else-if="slotTakenBy(slot)"
                class="slot-picker__slot-badge slot-picker__slot-badge--taken"
              >
                {{
                  t("labels.fleets.events.takenBy", {
                    username: slotTakenBy(slot)?.user?.username || "?",
                  })
                }}
              </span>
            </Btn>
          </li>
        </ul>

        <div
          v-for="ship in (team.ships ?? []) as FleetEventShip[]"
          :key="ship.id"
          class="slot-picker__ship"
        >
          <header class="slot-picker__ship-head">
            <i class="fa-light fa-rocket" />
            <span>{{ ship.displayTitle || ship.title || "Ship" }}</span>
            <span
              v-if="vehicleMatchesShip(signup.vehicle, ship)"
              v-tooltip="t('labels.fleets.events.vehicleFitsHint')"
              class="slot-picker__ship-fit"
            >
              <i class="fa-light fa-circle-check" />
            </span>
          </header>

          <ul
            v-if="ship.slots?.length"
            class="slot-picker__slots slot-picker__slots--ship"
          >
            <li
              v-for="slot in (ship.slots ?? []) as FleetEventSlot[]"
              :key="slot.id"
              class="slot-picker__slot"
            >
              <Btn
                :size="BtnSizesEnum.SMALL"
                inline
                variant="link"
                :disabled="
                  slot.id === currentSlotId ||
                  !!slotTakenBy(slot) ||
                  assignMutation.isPending.value
                "
                :title="
                  slot.id === currentSlotId
                    ? t('labels.fleets.events.currentSlotHint')
                    : slotTakenBy(slot)
                      ? t('labels.fleets.events.slotTakenHint')
                      : ''
                "
                @click="submit(slot)"
              >
                <span class="slot-picker__slot-label">{{ slot.title }}</span>
                <span
                  v-if="slot.positionType"
                  class="slot-picker__slot-type text-muted"
                >
                  {{ slot.positionType }}
                </span>
                <span
                  v-if="slot.id === currentSlotId"
                  class="slot-picker__slot-badge slot-picker__slot-badge--current"
                >
                  {{ t("labels.fleets.events.currentSlot") }}
                </span>
                <span
                  v-else-if="slotTakenBy(slot)"
                  class="slot-picker__slot-badge slot-picker__slot-badge--taken"
                >
                  {{
                    t("labels.fleets.events.takenBy", {
                      username: slotTakenBy(slot)?.user?.username || "?",
                    })
                  }}
                </span>
              </Btn>
            </li>
          </ul>
        </div>
      </section>

      <p v-if="!teams.length" class="text-muted">
        {{ t("labels.fleets.missions.noTeams") }}
      </p>
    </div>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :size="BtnSizesEnum.LARGE"
          inline
          variant="link"
          @click="comlink.emit('close-modal')"
        >
          {{ t("actions.cancel") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.slot-picker {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  max-height: 60vh;
  overflow-y: auto;
}
.slot-picker__team {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  padding: 0.6rem 0.8rem;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 4px;
}
.slot-picker__team-head {
  display: flex;
  align-items: center;
  gap: 0.45rem;
  font-size: 0.95rem;

  i {
    color: var(--text-muted);
  }
}
.slot-picker__ship {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  margin-left: 1rem;
  padding: 0.4rem 0.6rem;
  background: rgba(255, 255, 255, 0.02);
  border-left: 2px solid rgba(255, 255, 255, 0.1);
  border-radius: 0 4px 4px 0;
}
.slot-picker__ship-head {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  font-size: 0.88rem;

  i {
    color: var(--text-muted);
  }
}
.slot-picker__ship-fit {
  color: var(--success, #4caf50);
  margin-left: 0.2rem;
}
.slot-picker__slots {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
}
.slot-picker__slots--ship {
  margin-top: 0.2rem;
}
.slot-picker__slot {
  display: flex;
}
.slot-picker__slot-label {
  text-align: left;
  flex: 1;
}
.slot-picker__slot-type {
  font-size: 0.72rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  margin-left: 0.4rem;
}
.slot-picker__slot-badge {
  margin-left: 0.5rem;
  font-size: 0.7rem;
  padding: 0.1rem 0.4rem;
  border-radius: 999px;
}
.slot-picker__slot-badge--current {
  background: rgba(74, 170, 170, 0.18);
  color: var(--accent, #4aa);
}
.slot-picker__slot-badge--taken {
  background: rgba(255, 255, 255, 0.08);
  color: var(--text-muted);
}
.small {
  font-size: 0.78rem;
}
</style>
