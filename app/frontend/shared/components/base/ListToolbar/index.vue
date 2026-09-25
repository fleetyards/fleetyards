<script lang="ts">
export default {
  name: "BaseListToolbar",
};
</script>

<script lang="ts" setup generic="T">
import ListToolbarChip from "@/shared/components/base/ListToolbar/Chip/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { uniq as uniqArray } from "@/shared/utils/Array";
import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";

type Props = {
  columns: BaseTableCol<T>[];
  defaultSort?: string;
  // Puts the list's select-all box in front of the chips and its bulk actions
  // under them, for a list whose rows can be picked. `recordIds` are the rows
  // on screen, which is what the box selects.
  selectable?: boolean;
  recordIds?: string[];
  selectionDisabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  defaultSort: undefined,
  selectable: false,
  recordIds: () => [],
  selectionDisabled: false,
});

const selected = defineModel<string[]>("selected", { default: () => [] });

defineSlots<{
  "selected-actions"?: (props: { selected: string[] }) => void;
}>();

const { t } = useI18n();

// The same column list the table is built from, so a column that gains or
// loses its sort does so in both places at once -- and the metric columns,
// which appear only when the rows on screen carry the figure, bring their chip
// with them.
//
// A heading is only a sort control while it is on screen: the table scrolls
// sideways on a narrow window and the row it was sorted by scrolls out of
// reach. This line stays put.
const sortable = computed(() =>
  props.columns.filter((column) => column.sortable && column.label),
);

// Rows picked on other pages stay picked: the box only speaks for this page.
const allSelected = computed(
  () =>
    !!props.recordIds.length &&
    props.recordIds.every((id) => selected.value.includes(id)),
);

const someSelected = computed(() =>
  props.recordIds.some((id) => selected.value.includes(id)),
);

const onSelectAll = (value?: boolean) => {
  selected.value = value
    ? [...selected.value, ...props.recordIds].filter(uniqArray)
    : selected.value.filter((id) => !props.recordIds.includes(id));
};
</script>

<template>
  <div
    v-if="sortable.length || props.selectable"
    class="base-list-toolbar"
    :class="{ 'base-list-toolbar--selectable': props.selectable }"
  >
    <FormCheckbox
      v-if="props.selectable"
      class="base-list-toolbar__select-all"
      :disabled="props.selectionDisabled || !props.recordIds.length"
      name="all"
      :model-value="allSelected"
      inline
      no-label
      :partial="someSelected && !allSelected"
      data-test="list-toolbar-select-all"
      @update:model-value="onSelectAll"
    />
    <template v-if="sortable.length">
      <span class="base-list-toolbar__label">{{ t("actions.sortBy") }}</span>
      <ListToolbarChip
        v-for="column in sortable"
        :key="`sort-chip-${column.name}`"
        :label="column.label"
        :field="String(column.attributeKey || column.name)"
        :fallback="props.defaultSort"
      />
    </template>
    <!-- At the far end of the same line, so picking a row does not push the
         list down by a row of buttons. -->
    <transition name="base-list-toolbar-fade">
      <div
        v-if="props.selectable && selected.length"
        class="base-list-toolbar__bulk"
        data-test="list-toolbar-bulk"
      >
        <span class="base-list-toolbar__count">
          {{ t("filteredTable.labels.selected", { count: selected.length }) }}
          <Btn
            v-tooltip="t('filteredTable.actions.unselect')"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="t('filteredTable.actions.unselect')"
            @click="selected = []"
          >
            <i class="fa fa-times" />
          </Btn>
        </span>
        <slot name="selected-actions" :selected="selected" />
      </div>
    </transition>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
