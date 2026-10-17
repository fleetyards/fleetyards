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

// The board's view, as the ship page's hardpoints have it: compact folds every
// socket's contents away, expanded opens them all, and each socket's own
// chevron overrides either until the view changes again.
const density = inject<Ref<"compact" | "expanded">>(
  "loadoutSocketDensity",
  ref("expanded"),
);

const toggled = ref<Record<string, boolean>>({});

watch(density, () => {
  toggled.value = {};
});

// The socket being filled stays in sight, whichever way its parent was folded.
const holdsActive = (socket: LoadoutSocketSlot): boolean =>
  !!props.active &&
  (socket.children ?? []).some(
    (child) => child.id === props.active || holdsActive(child),
  );

const expanded = (socket: LoadoutSocketSlot) =>
  holdsActive(socket) ||
  (toggled.value[socket.id] ?? density.value === "expanded");

const toggle = (socket: LoadoutSocketSlot) => {
  toggled.value = { ...toggled.value, [socket.id]: !expanded(socket) };
};
</script>

<template>
  <ul
    class="loadout-socket-tree"
    :class="{ 'loadout-socket-tree--nested': nested }"
  >
    <li v-for="socket in slots" :key="socket.id">
      <div class="loadout-socket-tree__row">
        <Socket
          :socket="socket"
          :active="editable && socket.id === active"
          :editable="editable && !socket.locked"
          @select="emit('select', socket.id)"
        />
        <button
          v-if="socket.children?.length"
          type="button"
          class="loadout-socket-tree__toggle"
          :aria-expanded="expanded(socket)"
          :aria-label="
            t(expanded(socket) ? 'labels.collapse' : 'labels.expand')
          "
          :data-test="`loadout-socket-toggle-${socket.id}`"
          @click="toggle(socket)"
        >
          <i
            class="fa-solid"
            :class="expanded(socket) ? 'fa-chevron-up' : 'fa-chevron-down'"
            aria-hidden="true"
          />
        </button>
      </div>
      <!-- Directly under the socket it fills, for a caller with no room
           beside the board, such as a phone's width. -->
      <div
        v-if="editable && socket.id === active && $slots.active"
        class="loadout-socket-tree__active"
        data-test="loadout-socket-board-active"
      >
        <slot name="active" />
      </div>
      <Collapsed
        v-if="socket.children?.length"
        :visible="expanded(socket)"
        :duration="200"
      >
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

.loadout-socket-tree__row {
  display: flex;
  align-items: center;
  gap: 6px;
}

// The ship page's row control: a fixed square beside the socket, so every
// socket's edge lines up whether it holds anything or not.
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
