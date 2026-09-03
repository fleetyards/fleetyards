<script lang="ts">
export default {
  name: "BulkSelectionBar",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  selectedCount: number;
  matchingCount: number;
  pageSelected: boolean;
  pagePartiallySelected: boolean;
  canSelectAllMatching: boolean;
  allMatchingSelected: boolean;
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  disabled: false,
});

const emit = defineEmits<{
  "toggle-page": [selected: boolean];
  "select-all-matching": [];
  clear: [];
}>();

const { t } = useI18n();

const hasSelection = computed(() => props.selectedCount > 0);

// Three states, three things the box does - and the label has to say which,
// since a minus box that clears is not what a minus box does everywhere. It
// stays on the control as its accessible name while the box is disabled and
// the tooltip does not, because there is nothing to hover about a list with no
// rows to tick.
const pageLabel = computed(() => {
  if (props.pagePartiallySelected) {
    return t("bulkSelection.actions.clear");
  }

  if (props.pageSelected) {
    return t("bulkSelection.actions.unselectPage");
  }

  return t("bulkSelection.actions.selectPage");
});

// A minus box means the reader ticked some of the page row by row, and the way
// out of that is to drop the selection rather than to grow it to all 25:
// "select everything here" is not the undo for "I picked these three". Ticking
// the whole page from a partial one is then two clicks - clear, then tick -
// which is the rarer of the two moves.
const onTogglePage = (value?: boolean) => {
  if (props.pagePartiallySelected) {
    emit("clear");

    return;
  }

  emit("toggle-page", !!value);
};
</script>

<template>
  <div class="bulk-selection-bar" data-test="bulk-selection-bar">
    <!-- The checkbox and the count it belongs to are one line and stay one
         line. The bar wraps on a phone, and with the count free to wrap on its
         own the checkbox was centred against a two-line body - stranded
         halfway down the bar beside the buttons, reading as one of them rather
         than as the thing that ticks the page. -->
    <div class="bulk-selection-bar__lead">
      <FormCheckbox
        :model-value="props.pageSelected"
        :partial="props.pagePartiallySelected"
        :disabled="props.disabled"
        v-tooltip="props.disabled ? '' : pageLabel"
        :aria-label="pageLabel"
        name="bulk-selection-page"
        data-test="bulk-select-page"
        no-label
        inline
        @update:model-value="onTogglePage"
      />

      <span
        class="bulk-selection-bar__count"
        :class="{ 'bulk-selection-bar__count--empty': !hasSelection }"
      >
        <span data-test="bulk-selection-count">
          {{
            props.allMatchingSelected
              ? t("bulkSelection.labels.allMatchingSelected", {
                  count: props.selectedCount,
                })
              : t("bulkSelection.labels.selected", {
                  count: props.selectedCount,
                })
          }}
        </span>
        <Btn
          v-if="props.canSelectAllMatching"
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          data-test="bulk-select-all-matching"
          @click="emit('select-all-matching')"
        >
          {{
            t("bulkSelection.actions.selectAllMatching", {
              count: props.matchingCount,
            })
          }}
        </Btn>
      </span>
    </div>

    <div
      class="bulk-selection-bar__actions"
      :class="{ 'bulk-selection-bar__actions--empty': !hasSelection }"
    >
      <slot />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
