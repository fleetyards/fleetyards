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

defineProps<Props>();
const emit = defineEmits<{
  "update:activeId": [value: string];
}>();

const activate = (item: TabNavViewAnchorItem) => {
  if (item.disabled) return;
  emit("update:activeId", item.id);
};

const onKeydown = (event: KeyboardEvent, item: TabNavViewAnchorItem) => {
  if (event.key === "Enter" || event.key === " ") {
    event.preventDefault();
    activate(item);
  }
};
</script>

<template>
  <li
    v-for="item in items"
    :key="item.id"
    role="tab"
    :class="{
      active: item.id === activeId,
      disabled: item.disabled,
      'has-errors': item.invalid,
    }"
    :aria-selected="item.id === activeId"
    :aria-disabled="item.disabled || undefined"
    :tabindex="item.disabled ? -1 : 0"
    :data-tab-id="item.id"
    :data-test="`tab-anchor-${item.id}`"
    @click="activate(item)"
    @keydown="onKeydown($event, item)"
  >
    <a>{{ item.label }}</a>
  </li>
</template>
