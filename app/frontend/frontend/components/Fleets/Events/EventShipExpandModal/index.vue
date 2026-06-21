<script lang="ts">
export default {
  name: "FleetEventsShipExpandModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type Fleet,
  type FleetEvent,
  type FleetEventShip,
  type FleetEventSlot,
  type FleetEventTeam,
  type ModelPosition,
  useExpandFleetEventShipFromModel,
  useModelPositions,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  fleet: Fleet;
  event: FleetEvent;
  team: FleetEventTeam;
  ship: FleetEventShip;
  modelId: string;
  modelSlug: string;
  modelName: string;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const slug = computed(() => props.modelSlug);
const { data: positions, isLoading } = useModelPositions(slug);

const existingPositionIds = computed(
  () =>
    new Set(
      ((props.ship.slots ?? []) as FleetEventSlot[])
        .map((s) => s.modelPositionId)
        .filter((id): id is string => !!id),
    ),
);

const availablePositions = computed<ModelPosition[]>(() =>
  (positions.value ?? []).filter((p) => !existingPositionIds.value.has(p.id)),
);

const selected = ref<Set<string>>(new Set());

watch(availablePositions, (positions) => {
  // Default-select all available positions when the list arrives.
  if (selected.value.size === 0) {
    selected.value = new Set(positions.map((p) => p.id));
  }
});

const toggle = (id: string) => {
  const next = new Set(selected.value);
  if (next.has(id)) next.delete(id);
  else next.add(id);
  selected.value = next;
};

const selectAll = () => {
  selected.value = new Set(availablePositions.value.map((p) => p.id));
};

const clearAll = () => {
  selected.value = new Set();
};

const mutation = useExpandFleetEventShipFromModel();

const submit = async () => {
  if (selected.value.size === 0) return;
  try {
    await mutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      fleetEventSlug: props.event.slug,
      fleetEventTeamId: props.team.id,
      id: props.ship.id,
      data: {
        modelId: props.modelId,
        positionIds: Array.from(selected.value),
      },
    });
    displaySuccess({
      text: t("messages.fleets.eventShip.expand.success"),
    });
    comlink.emit("fleet-event-children-changed");
    comlink.emit("close-modal");
  } catch {
    displayAlert({
      text: t("messages.fleets.eventShip.expand.failure"),
    });
  }
};
</script>

<template>
  <Modal :title="t('headlines.fleets.events.expandShip')">
    <p class="text-muted">
      {{ t("labels.fleets.events.expandShipHint", { model: modelName }) }}
    </p>

    <p v-if="isLoading" class="text-muted">{{ t("labels.loading") }}</p>
    <p v-else-if="!availablePositions.length" class="text-muted">
      {{ t("labels.fleets.events.noExtraPositions") }}
    </p>

    <template v-else>
      <div class="expand-toolbar">
        <Btn
          :size="BtnSizesEnum.SMALL"
          inline
          variant="link"
          @click="selectAll"
        >
          {{ t("actions.selectAll") }}
        </Btn>
        <Btn :size="BtnSizesEnum.SMALL" inline variant="link" @click="clearAll">
          {{ t("actions.clear") }}
        </Btn>
      </div>

      <ul class="expand-positions">
        <li
          v-for="position in availablePositions"
          :key="position.id"
          class="expand-positions__item"
        >
          <label>
            <input
              type="checkbox"
              :checked="selected.has(position.id)"
              @change="toggle(position.id)"
            />
            <span>{{ position.name }}</span>
            <span
              v-if="position.positionType"
              class="expand-positions__type text-muted"
            >
              {{ position.positionType }}
            </span>
          </label>
        </li>
      </ul>
    </template>

    <template #actions>
      <Btn
        :size="BtnSizesEnum.SMALL"
        inline
        :disabled="selected.size === 0"
        :loading="mutation.isPending.value"
        @click="submit"
      >
        <i class="fa-light fa-square-plus" />
        {{ t("actions.fleets.events.addSeats") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.expand-toolbar {
  display: flex;
  gap: 0.4rem;
  margin: 0.4rem 0;
}
.expand-positions {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  max-height: 320px;
  overflow-y: auto;
}
.expand-positions__item label {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
  padding: 0.3rem 0.4rem;
  border-radius: 4px;

  &:hover {
    background: rgba(255, 255, 255, 0.04);
  }
}
.expand-positions__type {
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}
</style>
