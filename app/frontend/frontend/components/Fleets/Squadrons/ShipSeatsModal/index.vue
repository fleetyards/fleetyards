<script lang="ts">
export default {
  name: "FleetSquadronShipSeatsModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Avatar from "@/shared/components/Avatar/index.vue";
import SlotCandidatesEditor from "@/frontend/components/Fleets/Squadrons/SlotCandidatesEditor/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import {
  type LineupScope,
  useLineupApi,
} from "@/frontend/components/Fleets/Missions/useLineupApi";
import { useSlotRename } from "@/frontend/components/Fleets/Missions/useSlotRename";
import {
  sortByFilled,
  useSlotTitle,
} from "@/frontend/composables/useSlotTitle";
import { type MissionSlot, useFleetSquadronFlight } from "@/services/fyApi";

type Props = {
  scope: LineupScope;
  shipId: string;
  shipTitle: string;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), { editable: true });

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();
const slotTitle = useSlotTitle();

const lineup = useLineupApi(() => props.scope);

// Read live, so a seat added or filled here shows at once.
const { data: flight } = useFleetSquadronFlight(
  computed(() => props.scope.fleetSlug),
  computed(() => props.scope.squadronSlug ?? ""),
  computed(() => props.scope.flightId ?? ""),
);

// Filled seats first, then the open ones, each in the ship's own order.
const seats = computed<MissionSlot[]>(() =>
  sortByFilled(
    flight.value?.ships.find((ship) => ship.id === props.shipId)?.slots ?? [],
  ),
);

const editingId = ref<string | null>(null);
const editing = computed(() =>
  seats.value.find((seat) => seat.id === editingId.value),
);

const editor = ref<InstanceType<typeof SlotCandidatesEditor>>();

useModalDirty(() => !!editor.value?.dirty);

const changed = () => comlink.emit("mission-children-changed");

const {
  renamingId,
  renameValue,
  setRenameInput,
  startRename,
  cancelRename,
  saveRename,
} = useSlotRename(lineup, changed);

const summary = (seat: MissionSlot) => {
  const [primary, ...alternates] = seat.candidates ?? [];
  if (!primary) return t("labels.fleet.squadrons.flights.openSeat");
  if (!alternates.length) return primary.username;

  return `${primary.username} · ${t("labels.fleet.squadrons.flights.then", {
    names: alternates.map((candidate) => candidate.username).join(", "),
  })}`;
};

// The ship's last pilot seat stays: a ship always has someone to fly it.
const lastPilot = (seat: MissionSlot) =>
  seat.role === "pilot" &&
  seats.value.filter((other) => other.role === "pilot").length === 1;

const roleLabel = (seat: MissionSlot) =>
  seat.role ? t(`labels.fleet.squadrons.flights.roles.${seat.role}`) : null;

const newSeat = ref("");
const newRole = ref<"captain" | "pilot" | null>(null);

const addSeat = async () => {
  const title = newSeat.value.trim();
  if (!title) return;

  await lineup
    .createSlot({
      slottableType: "MissionShip",
      slottableId: props.shipId,
      title,
      role: newRole.value,
    })
    .then(() => {
      newSeat.value = "";
      newRole.value = null;
      changed();
    })
    .catch(() =>
      displayAlert({ text: t("messages.fleets.missionSlot.create.failure") }),
    );
};

const removeSeat = async (seat: MissionSlot) => {
  await lineup
    .destroySlot(seat.id)
    .then(changed)
    .catch(() =>
      displayAlert({ text: t("messages.fleets.missionSlot.destroy.failure") }),
    );
};
</script>

<template>
  <Modal
    :title="
      editing
        ? t('headlines.fleets.squadrons.flights.candidates', {
            slot: slotTitle(editing),
          })
        : t('headlines.fleets.squadrons.flights.seats', {
            ship: props.shipTitle,
          })
    "
  >
    <template v-if="editing">
      <SlotCandidatesEditor
        :key="editing.id"
        ref="editor"
        :slot="editing"
        :scope="props.scope"
        @saved="editingId = null"
      />
    </template>

    <template v-else>
      <ul class="ship-seats">
        <li
          v-for="seat in seats"
          :key="seat.id"
          class="ship-seats__row"
          :data-test="`ship-seat-${seat.id}`"
        >
          <Avatar
            v-if="seat.candidates?.length"
            :avatar="seat.candidates[0].avatar?.smallUrl"
            size="small"
          />
          <span v-else class="ship-seats__open" aria-hidden="true">
            <i class="fa-light fa-plus" />
          </span>
          <div class="ship-seats__text">
            <span class="ship-seats__title">
              <input
                v-if="renamingId === seat.id"
                :ref="setRenameInput"
                v-model="renameValue"
                type="text"
                class="ship-seats__title-input"
                :aria-label="t('actions.fleet.squadrons.flights.renameSeat')"
                :data-test="`ship-seat-edit-${seat.id}`"
                @keydown.enter.prevent="saveRename(seat)"
                @keydown.esc="cancelRename"
                @blur="saveRename(seat)"
              />
              <button
                v-else-if="props.editable"
                v-tooltip="t('actions.fleet.squadrons.flights.renameSeat')"
                type="button"
                class="ship-seats__title-btn"
                :data-test="`ship-seat-title-${seat.id}`"
                @click="startRename(seat)"
              >
                {{ slotTitle(seat) }}
              </button>
              <template v-else>{{ slotTitle(seat) }}</template>
              <span v-if="roleLabel(seat)" class="ship-seats__role">
                {{ roleLabel(seat) }}
              </span>
            </span>
            <span
              class="ship-seats__who"
              :class="{ 'ship-seats__who--open': !seat.candidates?.length }"
            >
              {{ summary(seat) }}
            </span>
          </div>
          <Btn
            v-if="props.editable"
            :size="BtnSizesEnum.SM"
            :data-test="`ship-seat-fill-${seat.id}`"
            @click="editingId = seat.id"
          >
            {{
              seat.candidates?.length
                ? t("actions.fleet.squadrons.flights.changeMembers")
                : t("actions.fleet.squadrons.flights.fillSeat")
            }}
          </Btn>
          <Btn
            v-if="props.editable && !lastPilot(seat)"
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="t('actions.fleet.squadrons.flights.removeSeat')"
            @click="removeSeat(seat)"
          >
            <i class="fa-light fa-xmark" />
          </Btn>
        </li>
      </ul>

      <p v-if="!seats.length" class="ship-seats__empty">
        {{ t("labels.fleets.missions.noSlots") }}
      </p>

      <form
        v-if="props.editable"
        class="ship-seats__new"
        @submit.prevent="addSeat"
      >
        <input
          v-model="newSeat"
          type="text"
          class="ship-seats__new-input"
          :aria-label="t('actions.fleets.missions.addSlot')"
          :placeholder="t('actions.fleets.missions.addSlot')"
          data-test="ship-seat-new"
        />
        <select
          v-model="newRole"
          class="ship-seats__new-role"
          :aria-label="t('labels.fleet.squadrons.flights.role')"
          data-test="ship-seat-new-role"
        >
          <option :value="null">
            {{ t("labels.fleet.squadrons.flights.roles.crew") }}
          </option>
          <option value="captain">
            {{ t("labels.fleet.squadrons.flights.roles.captain") }}
          </option>
          <option value="pilot">
            {{ t("labels.fleet.squadrons.flights.roles.pilot") }}
          </option>
        </select>
      </form>
    </template>

    <template #footer>
      <template v-if="editing">
        <Btn :variant="BtnVariantsEnum.BARE" @click="editingId = null">
          {{ t("actions.back") }}
        </Btn>
        <Btn
          :loading="editor?.pending"
          data-test="slot-candidates-save"
          @click="editor?.submit()"
        >
          {{ t("actions.save") }}
        </Btn>
      </template>
      <Btn
        v-else
        data-test="ship-seats-done"
        @click="comlink.emit('close-modal')"
      >
        {{ t("actions.done") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.ship-seats {
  display: flex;
  flex-direction: column;
  margin: 0 0 12px;
  padding: 0;
  list-style: none;
}

.ship-seats__row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  padding: 10px 0;
  border-bottom: 1px solid var(--color-edge-faint);
}

.ship-seats__open {
  display: grid;
  flex-shrink: 0;
  width: 30px;
  height: 30px;
  border: 1px dashed var(--color-edge-strong);
  border-radius: 50%;
  color: var(--color-muted);
  font-size: 0.75rem;
  place-items: center;
}

.ship-seats__text {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 2px;
  min-width: 160px;
}

.ship-seats__title {
  display: inline-flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  font-weight: 600;
}

.ship-seats__title-btn {
  margin: -2px -6px;
  padding: 2px 6px;
  border: none;
  border-radius: var(--radius-control-bare);
  background: transparent;
  color: inherit;
  font: inherit;
  text-align: left;
  cursor: text;

  &:hover {
    background: var(--color-control-press);
  }
}

.ship-seats__title-input {
  min-width: 0;
  margin: -3px -7px;
  padding: 2px 6px;
  border: 1px solid var(--color-primary);
  border-radius: var(--radius-control-bare);
  background: transparent;
  color: inherit;
  font: inherit;
  outline: none;
}

.ship-seats__role {
  padding: 1px 6px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 4px;
  color: var(--color-text-dim);
  font-size: 0.625rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.ship-seats__new {
  display: flex;
  gap: 8px;
}

.ship-seats__new-role {
  padding: 4px 6px;
  border: 1px solid var(--color-edge-soft);
  border-radius: var(--radius-control-bare);
  background: transparent;
  color: inherit;
  font: inherit;
  font-size: 0.8125rem;
}

.ship-seats__who {
  font-size: 0.8125rem;
}

.ship-seats__who--open,
.ship-seats__empty {
  color: var(--color-muted);
}

.ship-seats__empty {
  margin: 0 0 12px;
  font-style: italic;
}

.ship-seats__new-input {
  flex: 1;
  min-width: 0;
  padding: 6px 8px;
  border: 1px dashed var(--color-edge-soft);
  border-radius: var(--radius-control-bare);
  background: transparent;
  color: inherit;
  font: inherit;
  font-size: 0.8125rem;

  &:focus {
    border-style: solid;
    border-color: var(--color-primary);
    outline: none;
  }
}
</style>
