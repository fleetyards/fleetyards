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
      v-tooltip="t('filterGroup.labels.removeTooltip')"
    >
      <i class="fal fa-plus" />
    </span>
  </a>
</template>

<script lang="ts" setup>
import { FilterOption } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  option: FilterOption;
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

const { t } = useI18n();

const emit = defineEmits(["select"]);

const select = (option: FilterOption) => {
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
