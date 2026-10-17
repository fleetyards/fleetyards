<script lang="ts">
export default {
  name: "LoadoutSocketTree",
};
</script>

<script lang="ts" setup>
import Socket from "@/frontend/components/Loadout/Socket/index.vue";
import type { LoadoutSocketSlot } from "@/frontend/components/Loadout/Socket/types";

type Props = {
  slots: LoadoutSocketSlot[];
  active?: string;
  editable?: boolean;
  nested?: boolean;
};

withDefaults(defineProps<Props>(), {
  active: undefined,
  editable: false,
  nested: false,
});

const emit = defineEmits<{
  select: [slotId: string];
}>();
</script>

<template>
  <ul
    class="loadout-socket-tree"
    :class="{ 'loadout-socket-tree--nested': nested }"
  >
    <li v-for="socket in slots" :key="socket.id">
      <Socket
        :socket="socket"
        :active="editable && socket.id === active"
        :editable="editable && !socket.locked"
        @select="emit('select', socket.id)"
      />
      <!-- Directly under the socket it fills, for a caller with no room
           beside the board, such as a phone's width. -->
      <div
        v-if="editable && socket.id === active && $slots.active"
        class="loadout-socket-tree__active"
        data-test="loadout-socket-board-active"
      >
        <slot name="active" />
      </div>
      <LoadoutSocketTree
        v-if="socket.children?.length"
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
