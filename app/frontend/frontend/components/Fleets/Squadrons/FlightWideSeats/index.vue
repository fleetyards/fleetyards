<script lang="ts">
export default {
  name: "FleetSquadronFlightWideSeats",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Avatar from "@/shared/components/Avatar/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type LineupScope,
  useLineupApi,
} from "@/frontend/components/Fleets/Missions/useLineupApi";
import { type MissionSlot } from "@/services/fyApi";
import {
  sortByFilled,
  useSlotTitle,
} from "@/frontend/composables/useSlotTitle";
import Sortable from "sortablejs";

type Props = {
  scope: LineupScope;
  seats: MissionSlot[];
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), { editable: false });

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const lineup = useLineupApi(() => props.scope);
const slotTitle = useSlotTitle();

const sortedSeats = computed(() => sortByFilled(props.seats));

const changed = () => comlink.emit("mission-children-changed");

const openCandidates = (seat: MissionSlot) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SlotCandidatesModal/index.vue"),
    props: { slot: seat, scope: props.scope },
  });
};

const newSeat = ref("");

const addSeat = async () => {
  const title = newSeat.value.trim();
  if (!title) return;

  await lineup
    .createSlot({
      slottableType: "MissionTeam",
      slottableId: props.scope.teamId,
      title,
    })
    .then(() => {
      newSeat.value = "";
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

const list = ref<HTMLElement | null>(null);
let sortable: Sortable | null = null;

const initSortable = () => {
  sortable?.destroy();
  if (!list.value || !props.editable) return;

  sortable = Sortable.create(list.value, {
    animation: 150,
    handle: ".wide-seats__grip",
    filter: "[data-lead]",
    onEnd: () => {
      // The lead heads the list whatever the order, so it is not sorted.
      const order = Array.from(
        list.value?.querySelectorAll("[data-seat-id]:not([data-lead])") ?? [],
      )
        .map((el) => el.getAttribute("data-seat-id"))
        .filter(Boolean) as string[];

      void lineup
        .sortSlots({
          slottableType: "MissionTeam",
          slottableId: props.scope.teamId,
          sorting: order,
        })
        .then(changed)
        .catch(() =>
          displayAlert({
            text: t("messages.fleets.missionSlot.update.failure"),
          }),
        );
    },
  });
};

watch(
  () => [props.seats, props.editable],
  () => void nextTick(initSortable),
);

onMounted(() => void nextTick(initSortable));
onUnmounted(() => sortable?.destroy());
</script>

<template>
  <section class="wide-seats" data-test="flight-wide-seats">
    <header class="wide-seats__header">
      <div>
        <Heading :level="HeadingLevelEnum.H2">
          {{ t("headlines.fleets.squadrons.flights.wideSeats") }}
        </Heading>
        <p class="wide-seats__hint">
          {{ t("texts.fleet.squadrons.flights.wideSeatsHint") }}
        </p>
      </div>
    </header>

    <div class="wide-seats__panel">
      <ul ref="list" class="wide-seats__list">
        <li
          v-for="seat in sortedSeats"
          :key="seat.id"
          :data-seat-id="seat.id"
          :data-lead="seat.lead || undefined"
          class="wide-seats__row"
          :data-test="`flight-wide-seat-${seat.id}`"
        >
          <span
            v-if="editable && !seat.lead"
            v-tooltip="t('actions.reorder')"
            class="wide-seats__grip"
            :aria-label="t('actions.reorder')"
          >
            <i class="fa-light fa-grip-vertical" />
          </span>
          <span v-else-if="editable" class="wide-seats__grip-space" />
          <span class="wide-seats__title">
            <i
              v-if="seat.lead"
              class="fa-duotone fa-star wide-seats__lead-icon"
              aria-hidden="true"
            />
            {{ slotTitle(seat) }}
          </span>
          <ol class="wide-seats__queue">
            <template
              v-for="(candidate, index) in seat.candidates ?? []"
              :key="candidate.id"
            >
              <li
                class="wide-seats__chip"
                :class="{ 'wide-seats__chip--primary': index === 0 }"
              >
                <span class="wide-seats__rank">{{ index + 1 }}</span>
                <Avatar :avatar="candidate.avatar?.smallUrl" size="small" />
                <span>{{ candidate.username }}</span>
              </li>
              <li
                v-if="index < (seat.candidates?.length ?? 0) - 1"
                class="wide-seats__then"
                aria-hidden="true"
              >
                ›
              </li>
            </template>
            <li v-if="editable">
              <button
                type="button"
                class="wide-seats__add-member"
                :data-test="`flight-wide-seat-members-${seat.id}`"
                @click="openCandidates(seat)"
              >
                {{
                  seat.candidates?.length
                    ? t("actions.fleet.squadrons.flights.addAlternate")
                    : t("actions.fleet.squadrons.flights.assignMember")
                }}
              </button>
            </li>
            <li v-else-if="!seat.candidates?.length" class="wide-seats__nobody">
              {{ t("labels.fleet.squadrons.flights.nobodyListed") }}
            </li>
          </ol>
          <Btn
            v-if="editable && !seat.lead"
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="t('actions.fleet.squadrons.flights.removeSeat')"
            @click="removeSeat(seat)"
          >
            <i class="fa-light fa-xmark" />
          </Btn>
        </li>
      </ul>

      <p v-if="!seats.length && !editable" class="wide-seats__empty">
        {{ t("labels.fleets.missions.noSlots") }}
      </p>

      <form v-if="editable" class="wide-seats__new" @submit.prevent="addSeat">
        <input
          v-model="newSeat"
          type="text"
          class="wide-seats__new-input"
          :aria-label="t('actions.fleets.missions.addSlot')"
          :placeholder="t('actions.fleets.missions.addSlot')"
          data-test="flight-wide-seat-new"
        />
      </form>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.wide-seats {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.wide-seats__hint {
  margin: 4px 0 0;
  font-size: 0.8125rem;
  color: var(--color-text-dim);
}

.wide-seats__panel {
  border: 1px solid var(--color-edge-soft);
  border-radius: var(--radius-surface-slim);
  background: var(--color-surface);
  box-shadow: var(--shadow-surface-slim);
}

.wide-seats__list {
  margin: 0;
  padding: 0;
  list-style: none;
}

.wide-seats__row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px 16px;
  padding: 10px 16px;
  border-bottom: 1px solid var(--color-edge-faint);
}

.wide-seats__grip {
  color: var(--color-muted);
  cursor: grab;
}

.wide-seats__grip-space {
  width: 12px;
}

.wide-seats__title {
  display: inline-flex;
  flex: 0 0 180px;
  align-items: center;
  gap: 8px;
  font-weight: 600;
}

.wide-seats__lead-icon {
  color: var(--color-gold);
}

.wide-seats__queue {
  display: flex;
  flex: 1;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  min-width: 200px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.wide-seats__chip {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 32px;
  padding: 0 10px 0 4px;
  border: 1px solid var(--color-edge-soft);
  border-radius: var(--radius-control);
  background: var(--color-control-press);
}

.wide-seats__chip--primary {
  border-color: rgb(66 139 202 / 0.6);
  background: rgb(66 139 202 / 0.14);
  font-weight: 600;
}

.wide-seats__rank {
  display: grid;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: var(--color-edge-soft);
  font-size: 0.6875rem;
  font-weight: 700;
  place-items: center;
}

.wide-seats__then {
  color: var(--color-muted);
}

.wide-seats__add-member {
  height: 32px;
  padding: 0 10px;
  border: 1px dashed var(--color-edge);
  border-radius: var(--radius-control);
  background: transparent;
  color: var(--color-text-dim);
  font: inherit;
  font-size: 0.8125rem;
  cursor: pointer;

  &:hover {
    border-color: var(--color-edge-strong);
    color: var(--color-text);
  }
}

.wide-seats__nobody,
.wide-seats__empty {
  margin: 0;
  color: var(--color-muted);
  font-size: 0.8125rem;
  font-style: italic;
}

.wide-seats__empty {
  padding: 12px 16px;
}

.wide-seats__new {
  padding: 10px 16px;
}

.wide-seats__new-input {
  width: 100%;
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

@media (max-width: 767px) {
  .wide-seats__title {
    flex-basis: calc(100% - 80px);
  }
}
</style>
