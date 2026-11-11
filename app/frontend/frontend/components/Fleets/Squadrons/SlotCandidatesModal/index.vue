<script lang="ts">
export default {
  name: "FleetSquadronSlotCandidatesModal",
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
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { type LineupScope } from "@/frontend/components/Fleets/Missions/useLineupApi";
import {
  type FleetSquadronSlotCandidate,
  type VehiclePublic,
  useFleetSquadronMembers,
  useFleetVehicles,
  useUpdateFleetSquadronFlightSlotCandidates,
} from "@/services/fyApi";

type Props = {
  slot: {
    id: string;
    title: string;
    candidates?: FleetSquadronSlotCandidate[];
  };
  scope: LineupScope;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const fleetSlug = computed(() => props.scope.fleetSlug);
const squadronSlug = computed(() => props.scope.squadronSlug ?? "");

const { data: members, isLoading: membersLoading } = useFleetSquadronMembers(
  fleetSlug,
  squadronSlug,
  computed(() => ({ perPage: "all" })),
);

interface Entry {
  username: string;
  vehicleId: string | null;
}

const entries = ref<Entry[]>(
  (props.slot.candidates ?? []).map((candidate) => ({
    username: candidate.username ?? "",
    vehicleId: candidate.vehicle?.id ?? null,
  })),
);

// The ships the listed members give this squadron -- the only ones a flight
// may name for them. Asked for the listed members alone, so a large squadron
// does not run past a page.
const { data: vehicles } = useFleetVehicles(
  fleetSlug,
  computed(() => ({
    perPage: "240",
    q: {
      squadronSlugIn: [squadronSlug.value],
      memberIn: entries.value.map((entry) => entry.username),
    },
  })),
  { query: { enabled: computed(() => entries.value.length > 0) } },
);

const initial = JSON.stringify(entries.value);
useModalDirty(() => JSON.stringify(entries.value) !== initial);

const available = computed(() =>
  (members.value?.items ?? []).filter(
    (member) =>
      !entries.value.some((entry) => entry.username === member.username),
  ),
);

const shipsOf = (username: string) =>
  ((vehicles.value?.items ?? []) as VehiclePublic[]).filter(
    (vehicle) => vehicle.username === username,
  );

const shipLabel = (vehicle: VehiclePublic) =>
  vehicle.name
    ? `${vehicle.name} (${vehicle.model?.name})`
    : vehicle.model?.name;

const add = (username: string) => {
  entries.value = [...entries.value, { username, vehicleId: null }];
};

const remove = (index: number) => {
  entries.value = entries.value.filter((_entry, at) => at !== index);
};

const move = (index: number, offset: number) => {
  const target = index + offset;
  if (target < 0 || target >= entries.value.length) return;

  const next = [...entries.value];
  [next[index], next[target]] = [next[target], next[index]];
  entries.value = next;
};

const mutation = useUpdateFleetSquadronFlightSlotCandidates();

const onSubmit = async () => {
  await mutation
    .mutateAsync({
      fleetSlug: props.scope.fleetSlug,
      fleetSquadronSlug: squadronSlug.value,
      fleetSquadronFlightId: props.scope.flightId ?? "",
      id: props.slot.id,
      data: { candidates: entries.value },
    })
    .then(() => {
      displaySuccess({
        text: t("messages.fleet.squadrons.flights.candidates.success"),
      });
      comlink.emit("mission-children-changed");
      comlink.emit("close-modal", true);
    })
    .catch(() => {
      displayAlert({
        text: t("messages.fleet.squadrons.flights.candidates.failure"),
      });
    });
};
</script>

<template>
  <Modal
    :title="
      t('headlines.fleets.squadrons.flights.candidates', {
        slot: props.slot.title,
      })
    "
  >
    <p class="candidates-hint">
      {{ t("texts.fleet.squadrons.flights.candidatesHint") }}
    </p>

    <ol v-if="entries.length" class="candidates-order">
      <li
        v-for="(entry, index) in entries"
        :key="entry.username"
        class="candidates-order__row"
        :data-test="`slot-candidate-${entry.username}`"
      >
        <span class="candidates-order__rank">
          {{
            index === 0
              ? t("labels.fleet.squadrons.flights.primary")
              : t("labels.fleet.squadrons.flights.alternate", { count: index })
          }}
        </span>
        <span class="candidates-order__name">{{ entry.username }}</span>
        <select
          v-model="entry.vehicleId"
          class="candidates-order__ship"
          :aria-label="t('labels.fleet.squadrons.flights.ship')"
        >
          <option :value="null">
            {{ t("labels.fleet.squadrons.flights.anyShip") }}
          </option>
          <option
            v-for="vehicle in shipsOf(entry.username)"
            :key="vehicle.id"
            :value="vehicle.id"
          >
            {{ shipLabel(vehicle) }}
          </option>
        </select>
        <Btn
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          :disabled="index === 0"
          :aria-label="t('actions.moveUp')"
          @click="move(index, -1)"
        >
          <i class="fa-light fa-arrow-up" />
        </Btn>
        <Btn
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          :disabled="index === entries.length - 1"
          :aria-label="t('actions.moveDown')"
          @click="move(index, 1)"
        >
          <i class="fa-light fa-arrow-down" />
        </Btn>
        <Btn
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          :aria-label="t('actions.remove')"
          @click="remove(index)"
        >
          <i class="fa-light fa-xmark" />
        </Btn>
      </li>
    </ol>

    <Loader v-if="membersLoading" :loading="true" inline />

    <div v-else-if="available.length" class="candidates-pool">
      <button
        v-for="member in available"
        :key="member.id"
        type="button"
        class="candidates-pool__member"
        :data-test="`slot-candidate-option-${member.username}`"
        @click="add(member.username)"
      >
        <Avatar :avatar="member.avatar?.smallUrl" size="small" />
        <span>{{ member.username }}</span>
        <i class="fa-solid fa-circle-plus" />
      </button>
    </div>

    <template #footer>
      <Btn
        :loading="mutation.isPending.value"
        data-test="slot-candidates-save"
        @click="onSubmit"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.candidates-hint {
  margin-top: 0;
  color: var(--color-muted, #7a8288);
}

.candidates-order {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin: 0 0 16px;
  padding: 0;
  list-style: none;
}

.candidates-order__row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}

.candidates-order__rank {
  min-width: 90px;
  font-size: 0.75rem;
  color: var(--color-muted, #7a8288);
}

.candidates-order__name {
  flex: 1;
  min-width: 100px;
  font-weight: 600;
}

.candidates-order__ship {
  max-width: 220px;
  padding: 4px 6px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control-bare, 6px);
  background: transparent;
  color: inherit;
  font: inherit;
}

.candidates-pool {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 8px;
}

.candidates-pool__member {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control-bare, 6px);
  background: transparent;
  color: inherit;
  cursor: pointer;

  span {
    flex: 1;
    text-align: left;
  }
}
</style>
