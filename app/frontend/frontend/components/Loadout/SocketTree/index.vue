<script lang="ts">
export default {
  name: "LoadoutSocketTree",
};
</script>

<script lang="ts" setup>
import type { Ref } from "vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import Socket from "@/frontend/components/Loadout/Socket/index.vue";
import type { LoadoutSocketSlot } from "@/frontend/components/Loadout/Socket/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  slots: LoadoutSocketSlot[];
  active?: string;
  editable?: boolean;
  nested?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  active: undefined,
  editable: false,
  nested: false,
});

const emit = defineEmits<{
  select: [slotId: string];
}>();

const { t } = useI18n();

// What sits inside every part shows until its row's chevron folds it away, or
// the board folds them all; a row's own choice is cleared each time it does.
const folded = inject<Ref<boolean>>("loadoutSocketsFolded", ref(false));

const toggled = ref<Record<string, boolean>>({});

watch(folded, () => {
  toggled.value = {};
});

// Groups split out to fit their slots one by one.
const split = ref<Record<string, boolean>>({});

const contains = (socket: LoadoutSocketSlot, id: string): boolean =>
  (socket.children ?? []).some(
    (child) => child.id === id || contains(child, id),
  ) ||
  (socket.stack ?? []).some((slot) => slot.id === id || contains(slot, id));

// The socket being filled stays in sight, whichever way its parent was folded.
const expanded = (socket: LoadoutSocketSlot) =>
  (!!props.active && contains(socket, props.active)) ||
  (toggled.value[socket.id] ?? !folded.value);

const toggle = (socket: LoadoutSocketSlot) => {
  toggled.value = { ...toggled.value, [socket.id]: !expanded(socket) };
};

const isSplit = (socket: LoadoutSocketSlot) =>
  !!socket.stack?.length &&
  (split.value[socket.id] ||
    socket.stack.some((slot) => slot.id === props.active));

const toggleSplit = (socket: LoadoutSocketSlot) => {
  split.value = { ...split.value, [socket.id]: !split.value[socket.id] };
};

// A split group shows its slots in its place, each a row of its own.
const rows = computed(() =>
  props.slots.flatMap((socket) => (isSplit(socket) ? socket.stack! : [socket])),
);

const groupOf = (row: LoadoutSocketSlot) =>
  props.slots.find((socket) => socket.stack?.includes(row));
</script>

<template>
  <ul
    class="loadout-socket-tree"
    :class="{ 'loadout-socket-tree--nested': nested }"
  >
    <li v-for="socket in rows" :key="socket.id">
      <Socket
        :socket="socket"
        :active="editable && socket.id === active"
        :editable="editable && !socket.locked"
        @select="emit('select', socket.id)"
      >
        <template
          v-if="
            socket.stack?.length || groupOf(socket) || socket.children?.length
          "
          #actions
        >
          <span class="loadout-socket-tree__controls">
            <button
              v-if="socket.stack?.length || groupOf(socket)"
              type="button"
              class="loadout-socket-tree__toggle"
              :aria-expanded="!!groupOf(socket)"
              :aria-label="
                t(groupOf(socket) ? 'labels.collapse' : 'labels.expand')
              "
              :data-test="`loadout-socket-split-${socket.id}`"
              @click.stop="toggleSplit(groupOf(socket) || socket)"
            >
              <i
                class="fa-solid"
                :class="groupOf(socket) ? 'fa-compress' : 'fa-layer-group'"
                aria-hidden="true"
              />
            </button>
            <button
              v-if="socket.children?.length"
              type="button"
              class="loadout-socket-tree__toggle"
              :aria-expanded="expanded(socket)"
              :aria-label="
                t(expanded(socket) ? 'labels.collapse' : 'labels.expand')
              "
              :data-test="`loadout-socket-toggle-${socket.id}`"
              @click.stop="toggle(socket)"
            >
              <i
                class="fa-solid"
                :class="expanded(socket) ? 'fa-chevron-up' : 'fa-chevron-down'"
                aria-hidden="true"
              />
            </button>
          </span>
        </template>
        <template v-if="socket.children?.length" #children>
          <Collapsed :visible="expanded(socket)" :duration="200">
            <LoadoutSocketTree
              :slots="socket.children"
              :active="active"
              :editable="editable"
              nested
              @select="(id) => emit('select', id)"
            >
              <template v-if="$slots.active" #active>
                <slot name="active" />
              </template>
            </LoadoutSocketTree>
          </Collapsed>
        </template>
      </Socket>
      <!-- Directly under the socket it fills, for a caller with no room
           beside the board, such as a phone's width. -->
      <!-- A press inside the picker is the picker's: under a nested socket it
           sits inside the parent's row, which would take the click as its own. -->
      <div
        v-if="editable && socket.id === active && $slots.active"
        class="loadout-socket-tree__active"
        data-test="loadout-socket-board-active"
        @click.stop
      >
        <slot name="active" />
      </div>
    </li>
  </ul>
</template>

<style lang="scss" scoped>
.loadout-socket-tree {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 10px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.loadout-socket-tree__controls {
  display: flex;
  align-items: center;
  gap: 4px;
}

// The ship page's row control: a fixed square in the row's rail, so it sits in
// the same place on every row.
.loadout-socket-tree__toggle {
  flex: none;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  padding: 0;
  color: $gray-light;
  font-size: 11px;
  background: none;
  border: 1px solid rgba($gray-light, 0.35);
  border-radius: 6px;
  cursor: pointer;
  transition:
    color 0.15s,
    border-color 0.15s;

  &:hover {
    color: lighten($text-color, 15%);
    border-color: rgba($gray-light, 0.6);
  }

  &:focus-visible {
    outline: 2px solid var(--color-primary, #428bca);
    outline-offset: 2px;
  }
}

// The rail the ship page's hardpoint list hangs a mount's contents on.
.loadout-socket-tree--nested {
  position: relative;
  margin: 10px 0 0 20px;
  padding-left: 18px;
  border-left: 1px solid rgba($gray-light, 0.5);

  &::before {
    content: "";
    position: absolute;
    top: -10px;
    left: -1px;
    width: 1px;
    height: 12px;
    background: $primary;
    opacity: 0.5;
  }
}

.loadout-socket-tree__active {
  margin-top: 8px;
}
</style>
