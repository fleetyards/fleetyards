<script lang="ts">
export default {
  name: "BaseSelectOption",
};
</script>

<script lang="ts" setup>
import { FilterOption } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  option: FilterOption;
  selected?: boolean;
  multiple?: boolean;
  bigIcon?: boolean;
  nullable?: boolean;
  /*
   * A row inside the popover is an `option` in the listbox sense: it is not
   * focusable itself, the trigger keeps focus and points at it with
   * aria-activedescendant. The same component also renders the selected rows
   * that sit *outside* the popover, and those are not options of anything --
   * they are remove buttons, so they get to be real buttons.
   */
  inListbox?: boolean;
  optionId?: string;
  active?: boolean;
};

withDefaults(defineProps<Props>(), {
  selected: false,
  multiple: false,
  bigIcon: false,
  nullable: false,
  inListbox: false,
  optionId: undefined,
  active: false,
});

const { t } = useI18n();

const emit = defineEmits(["select"]);

const select = (option: FilterOption) => {
  emit("select", option);
};
</script>

<template>
  <component
    :is="inListbox ? 'div' : 'button'"
    :id="inListbox ? optionId : undefined"
    :role="inListbox ? 'option' : undefined"
    :aria-selected="inListbox ? selected : undefined"
    :tabindex="inListbox ? -1 : undefined"
    :type="inListbox ? undefined : 'button'"
    :class="{
      active: selected,
      bigIcon,
      'base-select-item--focused': active,
    }"
    class="base-select-item fade-list-item"
    @click="select(option)"
  >
    <span v-if="option.icon" class="base-select-item-icon">
      <img :src="option.icon" :alt="`option-icon`" />
    </span>
    <span class="base-select-item-label">
      {{ option.label }}
    </span>
    <span
      v-if="multiple || (selected && nullable)"
      v-tooltip="t('baseSelect.labels.removeTooltip')"
    >
      <!-- The glyph it means, rather than a plus rotated 45 degrees into one. -->
      <i :class="selected ? 'fa-light fa-xmark' : 'fa-light fa-plus'" />
    </span>
  </component>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
