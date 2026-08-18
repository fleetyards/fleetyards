<script lang="ts">
export default {
  name: "FleetMissionsSlotList",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type MissionSlot,
  useCreateMissionSlot,
  useUpdateMissionSlot,
  useDestroyMissionSlot,
  useSortMissionSlots,
} from "@/services/fyApi";
import Sortable from "sortablejs";

type SlottableType = "MissionTeam" | "MissionShip";

type Props = {
  slottableType: SlottableType;
  slottableId: string;
  slots: MissionSlot[];
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), { editable: false });

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const comlink = useComlink();

const localSlots = ref<MissionSlot[]>([]);
const editingId = ref<string | null>(null);
const editValue = ref("");
const newSlotValue = ref("");

watch(
  () => props.slots,
  (newSlots) => {
    localSlots.value = [...newSlots];
  },
  { immediate: true },
);

const createMutation = useCreateMissionSlot();
const updateMutation = useUpdateMissionSlot();
const destroyMutation = useDestroyMissionSlot();
const sortMutation = useSortMissionSlots();

const startEdit = (slot: MissionSlot) => {
  editingId.value = slot.id;
  editValue.value = slot.title;
  void nextTick(() => {
    const input = document.querySelector<HTMLInputElement>(
      `[data-slot-edit="${slot.id}"]`,
    );
    input?.focus();
    input?.select();
  });
};

const cancelEdit = () => {
  editingId.value = null;
  editValue.value = "";
};

const saveEdit = async (slot: MissionSlot) => {
  const next = editValue.value.trim();
  if (!next || next === slot.title) {
    cancelEdit();
    return;
  }

  await updateMutation
    .mutateAsync({
      id: slot.id,
      data: { title: next },
    })
    .then(() => {
      comlink.emit("mission-children-changed");
    })
    .catch(() =>
      displayAlert({ text: t("messages.fleets.missionSlot.update.failure") }),
    );

  cancelEdit();
};

const submitNew = async () => {
  const title = newSlotValue.value.trim();
  if (!title) return;

  await createMutation
    .mutateAsync({
      data: {
        slottableType: props.slottableType,
        slottableId: props.slottableId,
        title,
      },
    })
    .then(() => {
      newSlotValue.value = "";
      comlink.emit("mission-children-changed");
    })
    .catch(() =>
      displayAlert({ text: t("messages.fleets.missionSlot.create.failure") }),
    );
};

const removeSlot = async (slot: MissionSlot) => {
  await destroyMutation
    .mutateAsync({ id: slot.id })
    .then(() => {
      comlink.emit("mission-children-changed");
    })
    .catch(() =>
      displayAlert({ text: t("messages.fleets.missionSlot.destroy.failure") }),
    );
};

const container = ref<HTMLElement | null>(null);
let sortable: Sortable | null = null;

const initSortable = () => {
  sortable?.destroy();
  if (!container.value || !props.editable) return;
  sortable = Sortable.create(container.value, {
    animation: 150,
    handle: ".slot-drag-handle",
    onEnd: () => {
      const items = container.value?.querySelectorAll("[data-slot-id]");
      if (!items) return;
      const order = Array.from(items)
        .map((el) => el.getAttribute("data-slot-id"))
        .filter(Boolean) as string[];

      localSlots.value = order
        .map((id) => localSlots.value.find((s) => s.id === id))
        .filter(Boolean) as MissionSlot[];

      void sortMutation
        .mutateAsync({
          data: {
            slottableType: props.slottableType,
            slottableId: props.slottableId,
            sorting: order,
          },
        })
        .catch(() =>
          displayAlert({
            text: t("messages.fleets.missionSlot.update.failure"),
          }),
        );
    },
  });
};

watch([localSlots, () => props.editable], () => {
  void nextTick(() => initSortable());
});

onMounted(() => {
  void nextTick(() => initSortable());
});

onUnmounted(() => {
  sortable?.destroy();
});
</script>

<template>
  <div class="slot-list">
    <ul ref="container" class="slot-list-items">
      <li
        v-for="slot in localSlots"
        :key="slot.id"
        :data-slot-id="slot.id"
        class="slot-item"
        :class="{ 'is-derived': slot.derived }"
      >
        <span
          v-if="editable"
          v-tooltip="t('actions.reorder')"
          class="slot-drag-handle"
          :aria-label="t('actions.reorder')"
        >
          <i class="fa-light fa-grip-vertical" />
        </span>
        <span v-if="slot.positionType" class="slot-type-badge">
          {{ slot.positionType }}
        </span>
        <input
          v-if="editable && editingId === slot.id"
          v-model="editValue"
          :data-slot-edit="slot.id"
          class="slot-edit-input"
          type="text"
          @keyup.enter="saveEdit(slot)"
          @keyup.esc="cancelEdit"
          @blur="saveEdit(slot)"
        />
        <button
          v-else
          type="button"
          class="slot-title"
          :disabled="!editable"
          @click="editable && startEdit(slot)"
        >
          {{ slot.title }}
        </button>
        <button
          v-if="editable && editingId !== slot.id"
          type="button"
          class="slot-remove"
          :title="t('actions.delete')"
          @click="removeSlot(slot)"
        >
          ×
        </button>
      </li>
    </ul>

    <form v-if="editable" class="slot-add" @submit.prevent="submitNew">
      <input
        v-model="newSlotValue"
        type="text"
        class="slot-add-input"
        :placeholder="t('actions.fleets.missions.addSlot')"
      />
    </form>

    <p v-if="!localSlots.length && !editable" class="text-muted slot-empty">
      {{ t("labels.fleets.missions.noSlots") }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
.slot-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.slot-list-items {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
}
.slot-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 2px 4px;
  font-size: 13px;
  border-radius: var(--radius-control-bare, 6px);

  &:hover {
    background: var(--bg-subtle, rgba(255, 255, 255, 0.04));
  }

  &.is-derived .slot-title {
    color: var(--color-muted, #7a8288);
  }
}
.slot-drag-handle {
  cursor: grab;
  color: var(--color-muted, #7a8288);
  font-size: 12px;
  letter-spacing: -0.15em;
  user-select: none;
  flex-shrink: 0;
}
.slot-type-badge {
  font-size: 10px;
  text-transform: uppercase;
  color: var(--color-muted, #7a8288);
  flex-shrink: 0;
  padding: 0 4px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: 2px;
  letter-spacing: 0.04em;
}
.slot-title {
  flex: 1;
  text-align: left;
  background: transparent;
  border: none;
  padding: 2px 4px;
  cursor: text;
  color: inherit;
  font: inherit;
  border-radius: 2px;

  &:disabled {
    cursor: default;
  }

  &:not(:disabled):hover {
    background: var(--bg-elevated, rgba(255, 255, 255, 0.05));
  }
}
.slot-edit-input {
  flex: 1;
  background: var(--bg-elevated, rgba(255, 255, 255, 0.06));
  border: 1px solid var(--color-primary, #428bca);
  border-radius: 2px;
  padding: 2px 6px;
  font: inherit;
  color: inherit;
  outline: none;
}
.slot-remove {
  background: transparent;
  border: none;
  color: var(--color-muted, #7a8288);
  cursor: pointer;
  font-size: 16px;
  line-height: 1;
  padding: 0 4px;
  opacity: 0;
  transition:
    opacity 0.15s,
    color 0.15s;
  flex-shrink: 0;

  .slot-item:hover & {
    opacity: 1;
  }

  &:hover {
    color: var(--color-danger, #dc3545);
  }
}
.slot-add {
  margin-top: 2px;
}
.slot-add-input {
  width: 100%;
  background: transparent;
  border: 1px dashed var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control-bare, 6px);
  padding: 4px 6px;
  font: inherit;
  color: inherit;
  font-size: 13px;

  &:focus {
    outline: none;
    border-color: var(--color-primary, #428bca);
    border-style: solid;
  }
}
.slot-empty {
  font-style: italic;
  font-size: 13px;
  margin: 0;
}
</style>
