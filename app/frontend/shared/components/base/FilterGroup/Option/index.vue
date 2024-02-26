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
    <span class="filter-group-item-label">
      {{ option.label }}
    </span>
    <span
      v-if="multiple || (selected && nullable)"
      v-tooltip="i18n?.t('filterGroup.labels.removeTooltip')"
    >
      <i class="fal fa-plus" />
    </span>
  </a>
</template>

<script lang="ts" setup>
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

export type FilterGroupOption = {
  value: string;
  label: string;
  icon?: string;
};

type Props = {
  option: FilterGroupOption;
  selected?: boolean;
  multiple?: boolean;
  bigIcon?: boolean;
  nullable?: boolean;
};

withDefaults(defineProps<Props>(), {
  selected: false,
  multiple: false,
  bigIcon: false,
  nullable: false,
});

const i18n = inject<I18nPluginOptions>("i18n");

const emit = defineEmits(["select"]);

const select = (option: FilterGroupOption) => {
  emit("select", option);
};
</script>

<script lang="ts">
export default {
  name: "FilterGroupOption",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
