<script lang="ts">
export default {
  name: "LoadoutSocketBoard",
};
</script>

<script lang="ts" setup>
import SocketTree from "@/frontend/components/Loadout/SocketTree/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { LoadoutSocketGroup } from "@/frontend/components/Loadout/Socket/types";

type Props = {
  groups: LoadoutSocketGroup[];
  // The socket the picker is filling.
  active?: string;
  // The socket whose part is being crafted.
  crafting?: string;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  active: undefined,
  crafting: undefined,
  editable: false,
});

const emit = defineEmits<{
  "update:active": [slotId: string];
  craft: [slotId: string];
}>();

const { t } = useI18n();

// Folds every socket's contents at once, for a ship whose board runs long; a
// row's own chevron still opens or folds it alone afterwards.
const folded = ref(false);
provide("loadoutSocketsFolded", folded);

const nests = computed(() =>
  props.groups.some((group) =>
    group.slots.some((slot) => !!slot.children?.length),
  ),
);

const root = ref<HTMLElement>();

const sockets = () =>
  Array.from(
    root.value?.querySelectorAll<HTMLElement>(
      "[data-loadout-socket][role='button']",
    ) || [],
  );

// Up and down walk the sockets the way they read, across groups, so a long
// weapon board does not take a tab stop per socket to cross.
const onKeydown = (event: KeyboardEvent) => {
  const step = { ArrowDown: 1, ArrowUp: -1 }[event.key];
  if (!step || !props.editable) return;

  const all = sockets();
  const index = all.indexOf(document.activeElement as HTMLElement);
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
    <button
      v-if="nests"
      type="button"
      class="loadout-socket-board__fold"
      v-tooltip="t(folded ? 'labels.expand' : 'labels.collapse')"
      :aria-label="t(folded ? 'labels.expand' : 'labels.collapse')"
      :aria-pressed="folded"
      data-test="loadout-socket-board-fold"
      @click="folded = !folded"
    >
      <i
        class="fa-solid"
        :class="folded ? 'fa-chevron-down' : 'fa-chevron-up'"
        aria-hidden="true"
      />
    </button>
    <section
      v-for="group in groups"
      :key="group.key"
      class="loadout-socket-board__group"
      :data-test="`loadout-socket-group-${group.key}`"
    >
      <h4 v-if="group.label" class="loadout-socket-board__heading">
        {{ group.label }}
      </h4>
      <SocketTree
        :slots="group.slots"
        :active="active"
        :crafting="crafting"
        :editable="editable"
        @select="(id) => emit('update:active', id)"
        @craft="(id) => emit('craft', id)"
      >
        <template v-if="$slots.active" #active>
          <slot name="active" />
        </template>
      </SocketTree>
    </section>
  </div>
</template>

<style lang="scss" scoped>
// The rows' own control, the same small square, folding them all.
.loadout-socket-board__fold {
  display: flex;
  flex: none;
  align-self: flex-end;
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
</style>
