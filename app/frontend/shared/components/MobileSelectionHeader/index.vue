<script lang="ts">
export default {
  name: "MobileSelectionHeader",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import BulkSelectionBar from "@/shared/components/BulkSelectionBar/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";

type Props = {
  // A phone's selection mode, started by holding a row.
  selecting: boolean;
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

const mobile = useMobile();
</script>

<template>
  <!-- The bulk bar above a list - except on a phone, where it only exists
       while a held row has started a selection, and then stands in for the
       search in the header, where the thumb already is. -->
  <Teleport to="#header-left" :disabled="!props.selecting">
    <div
      v-if="!mobile || props.selecting"
      class="mobile-selection-header"
      :class="{
        'mobile-selection-header--active navigation-header-takeover navigation-header-pinned':
          props.selecting,
      }"
    >
      <Btn
        v-if="props.selecting"
        :variant="BtnVariantsEnum.BARE"
        :aria-label="t('bulkSelection.actions.clear')"
        data-test="bulk-exit"
        @click="emit('clear')"
      >
        <i class="fa-light fa-xmark" />
      </Btn>
      <BulkSelectionBar
        :disabled="props.disabled"
        :compact="props.selecting"
        :selected-count="props.selectedCount"
        :matching-count="props.matchingCount"
        :page-selected="props.pageSelected"
        :page-partially-selected="props.pagePartiallySelected"
        :can-select-all-matching="props.canSelectAllMatching"
        :all-matching-selected="props.allMatchingSelected"
        @toggle-page="emit('toggle-page', $event)"
        @select-all-matching="emit('select-all-matching')"
        @clear="emit('clear')"
      >
        <slot />
      </BulkSelectionBar>
    </div>
  </Teleport>
</template>

<style lang="scss" scoped>
.mobile-selection-header {
  display: flex;
  align-items: center;
  gap: 4px;

  > .bulk-selection-bar {
    flex: 1;
    min-width: 0;
  }
}

// In the header's search slot, which already has its insets: the bar keeps
// only the gap to the way out in front of it.
.mobile-selection-header--active > .bulk-selection-bar {
  padding: 0;
}
</style>
