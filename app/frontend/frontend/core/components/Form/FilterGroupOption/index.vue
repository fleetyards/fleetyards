<template>
  <a
    :class="{
      active: selected,
      bigIcon,
    }"
    class="filter-group-item fade-list-item"
    @click="select(option)"
  >
    <span v-if="option.icon" class="filter-group-item-icon">
      <img :src="option.icon" :alt="`option-icon`" />
    </span>
    <span v-html="option.label" />
    <span v-if="multiple">
      <i class="fal fa-plus" />
    </span>
  </a>
</template>

<script lang="ts" setup>
export type TFilterGroupOption = {
  value: string;
  label: string;
  icon?: string;
};

type Props = {
  option: TFilterGroupOption;
  selected?: boolean;
  multiple?: boolean;
  bigIcon?: boolean;
};

withDefaults(defineProps<Props>(), {
  selected: false,
  multiple: false,
  bigIcon: false,
});

const emit = defineEmits(["select"]);

const select = (option: TFilterGroupOption) => {
  emit("select", option);
};
</script>

<script lang="ts">
export default {
  name: "FilterGroupOption",
};
</script>
