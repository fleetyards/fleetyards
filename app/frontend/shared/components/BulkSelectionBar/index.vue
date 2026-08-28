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

const pageLabel = computed(() =>
  props.pageSelected
    ? t("bulkSelection.actions.unselectPage")
    : t("bulkSelection.actions.selectPage"),
);
</script>

<template>
  <div class="bulk-selection-bar" data-test="bulk-selection-bar">
    <FormCheckbox
      :model-value="props.pageSelected"
      :partial="props.pagePartiallySelected"
      :disabled="props.disabled"
      v-tooltip="pageLabel"
      :aria-label="pageLabel"
      name="bulk-selection-page"
      data-test="bulk-select-page"
      no-label
      inline
      @update:model-value="emit('toggle-page', $event)"
    />

    <div
      class="bulk-selection-bar__body"
      :class="{ 'bulk-selection-bar__body--empty': !hasSelection }"
    >
      <span class="bulk-selection-bar__count">
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
        <Btn
          v-tooltip="t('bulkSelection.actions.clear')"
          :aria-label="t('bulkSelection.actions.clear')"
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          data-test="bulk-selection-clear"
          @click="emit('clear')"
        >
          <i class="fa-duotone fa-xmark" />
        </Btn>
      </span>

      <div class="bulk-selection-bar__actions">
        <slot />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
