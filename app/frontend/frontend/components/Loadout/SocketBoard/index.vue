<script lang="ts">
export default {
  name: "LoadoutSocketBoard",
};
</script>

<script lang="ts" setup>
import Socket from "@/frontend/components/Loadout/Socket/index.vue";
import type { LoadoutSocketGroup } from "@/frontend/components/Loadout/Socket/types";

type Props = {
  groups: LoadoutSocketGroup[];
  // The socket the picker is filling.
  active?: string;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  active: undefined,
  editable: false,
});

const emit = defineEmits<{
  "update:active": [slotId: string];
}>();

const root = ref<HTMLElement>();

const sockets = () =>
  Array.from(
    root.value?.querySelectorAll<HTMLButtonElement>("button.loadout-socket") ||
      [],
  );

// Up and down walk the sockets the way they read, across groups, so a long
// weapon board does not take a tab stop per socket to cross.
const onKeydown = (event: KeyboardEvent) => {
  const step = { ArrowDown: 1, ArrowUp: -1 }[event.key];
  if (!step || !props.editable) return;

  const all = sockets();
  const index = all.indexOf(document.activeElement as HTMLButtonElement);
  if (index < 0) return;

  event.preventDefault();
  all[Math.min(Math.max(index + step, 0), all.length - 1)]?.focus();
};
</script>

<template>
  <div
    ref="root"
    class="loadout-socket-board"
    data-test="loadout-socket-board"
    @keydown="onKeydown"
  >
    <section
      v-for="group in groups"
      :key="group.key"
      class="loadout-socket-board__group"
      :data-test="`loadout-socket-group-${group.key}`"
    >
      <h4 v-if="group.label" class="loadout-socket-board__heading">
        {{ group.label }}
      </h4>
      <ul class="loadout-socket-board__sockets">
        <li v-for="socket in group.slots" :key="socket.id">
          <Socket
            :socket="socket"
            :active="editable && socket.id === active"
            :editable="editable"
            @select="emit('update:active', socket.id)"
          />
        </li>
      </ul>
    </section>
  </div>
</template>

<style lang="scss" scoped>
.loadout-socket-board {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.loadout-socket-board__heading {
  margin: 0 0 8px;
  color: var(--color-text-dim);
  font-size: 12px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.loadout-socket-board__sockets {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}
</style>
