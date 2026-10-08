<script lang="ts">
export default {
  name: "TabNavViewAnchorItems",
};
</script>

<script lang="ts" setup>
export type TabNavViewAnchorItem = {
  id: string;
  label: string;
  invalid?: boolean;
  disabled?: boolean;
};

type Props = {
  items: TabNavViewAnchorItem[];
  activeId?: string;
};

const props = defineProps<Props>();
const emit = defineEmits<{
  "update:activeId": [value: string];
}>();

const activate = (item: TabNavViewAnchorItem) => {
  if (item.disabled) return;
  emit("update:activeId", item.id);
};

const enabledItems = computed(() =>
  props.items.filter((item) => !item.disabled),
);

// One tab stop for the whole strip: the active tab, or the first enabled one
// while nothing enabled is active. The arrow keys reach the rest.
const focusableId = computed(() => {
  const active = enabledItems.value.find((item) => item.id === props.activeId);
  return (active || enabledItems.value[0])?.id;
});

const tabEls = ref<Record<string, HTMLElement>>({});

const setTabEl = (id: string, el: unknown) => {
  if (el instanceof HTMLElement) {
    tabEls.value[id] = el;
  } else {
    delete tabEls.value[id];
  }
};

const focusTab = (item: TabNavViewAnchorItem | undefined) => {
  if (item) tabEls.value[item.id]?.focus();
};

const onKeydown = (event: KeyboardEvent, item: TabNavViewAnchorItem) => {
  const enabled = enabledItems.value;
  const index = enabled.findIndex((entry) => entry.id === item.id);

  switch (event.key) {
    case "Enter":
    case " ":
      event.preventDefault();
      activate(item);
      break;
    case "ArrowDown":
    case "ArrowRight":
      event.preventDefault();
      focusTab(enabled[(index + 1) % enabled.length]);
      break;
    case "ArrowUp":
    case "ArrowLeft":
      event.preventDefault();
      focusTab(enabled[(index - 1 + enabled.length) % enabled.length]);
      break;
    case "Home":
      event.preventDefault();
      focusTab(enabled[0]);
      break;
    case "End":
      event.preventDefault();
      focusTab(enabled[enabled.length - 1]);
      break;
  }
};
</script>

<template>
  <li
    v-for="item in items"
    :key="item.id"
    :ref="(el) => setTabEl(item.id, el)"
    role="tab"
    :class="{
      active: item.id === activeId,
      disabled: item.disabled,
      'has-errors': item.invalid,
    }"
    :aria-selected="item.id === activeId"
    :aria-disabled="item.disabled || undefined"
    :tabindex="item.id === focusableId ? 0 : -1"
    :data-tab-id="item.id"
    :data-test="`tab-anchor-${item.id}`"
    @click="activate(item)"
    @keydown="onKeydown($event, item)"
  >
    <a>{{ item.label }}</a>
  </li>
</template>
