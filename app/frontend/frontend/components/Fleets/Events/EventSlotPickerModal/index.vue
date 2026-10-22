<script lang="ts">
export default {
  name: "FleetEventsSlotPickerModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
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
import { usePositionTypeLabel } from "@/frontend/composables/usePositionTypeLabel";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { firstErrorMessageFrom } from "@/shared/utils/ApiErrors";

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
const positionTypeLabel = usePositionTypeLabel();
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
  } catch (error) {
    const reason = firstErrorMessageFrom(error);

    displayAlert({
      text: reason || t("messages.fleets.eventSignup.update.failure"),
    });
    if (!reason) return;

    // The slots shown were captured when the modal opened, so a slot taken or
    // deleted since would fail the same way on every retry.
    comlink.emit("fleet-event-signup-changed");
    comlink.emit("close-modal");
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
    fill-body
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
              :size="BtnSizesEnum.SM"
              :variant="BtnVariantsEnum.BARE"
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
              <span v-if="slot.positionType" class="slot-picker__slot-type">
                {{ positionTypeLabel(slot.positionType) }}
              </span>
              <Pill
                v-if="slot.id === currentSlotId"
                class="slot-picker__slot-badge"
              >
                {{ t("labels.fleets.events.currentSlot") }}
              </Pill>
              <Pill
                v-else-if="slotTakenBy(slot)"
                class="slot-picker__slot-badge"
                :variant="PillVariantsEnum.NEUTRAL"
              >
                {{
                  t("labels.fleets.events.takenBy", {
                    username: slotTakenBy(slot)?.user?.username || "?",
                  })
                }}
              </Pill>
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
                :size="BtnSizesEnum.SM"
                :variant="BtnVariantsEnum.BARE"
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
                <span v-if="slot.positionType" class="slot-picker__slot-type">
                  {{ positionTypeLabel(slot.positionType) }}
                </span>
                <Pill
                  v-if="slot.id === currentSlotId"
                  class="slot-picker__slot-badge"
                >
                  {{ t("labels.fleets.events.currentSlot") }}
                </Pill>
                <Pill
                  v-else-if="slotTakenBy(slot)"
                  class="slot-picker__slot-badge"
                  :variant="PillVariantsEnum.NEUTRAL"
                >
                  {{
                    t("labels.fleets.events.takenBy", {
                      username: slotTakenBy(slot)?.user?.username || "?",
                    })
                  }}
                </Pill>
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
      <Btn :variant="BtnVariantsEnum.BARE" @click="comlink.emit('close-modal')">
        {{ t("actions.cancel") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "@/shared/components/rowLabel";
.slot-picker {
  display: flex;
  flex-direction: column;
  gap: 16px;
  min-height: 0;
  overflow-y: auto;
}
.slot-picker__team {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 10px 13px;
  background: rgba(255, 255, 255, 0.03);
  border-radius: var(--radius-control-bare, 6px);
}
.slot-picker__team-head {
  display: flex;
  align-items: center;
  gap: 7px;
  font-size: 15px;

  i {
    color: var(--color-muted, #7a8288);
  }
}
.slot-picker__ship {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-left: 16px;
  padding: 6px 10px;
  background: rgba(255, 255, 255, 0.02);
  border-left: 2px solid rgba(255, 255, 255, 0.1);
  border-radius: 0 4px 4px 0;
}
.slot-picker__ship-head {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;

  i {
    color: var(--color-muted, #7a8288);
  }
}
.slot-picker__ship-fit {
  color: var(--color-success, #5cb85c);
  margin-left: 4px;
}
.slot-picker__slots {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.slot-picker__slots--ship {
  margin-top: 4px;
}
.slot-picker__slot {
  display: flex;
}
.slot-picker__slot-label {
  text-align: left;
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
}
.slot-picker__slot-type {
  margin-left: 6px;
  white-space: nowrap;
  @include row-label;
}
.slot-picker__slot-badge {
  margin-left: 8px;
}
.small {
  font-size: 12px;
}
</style>
