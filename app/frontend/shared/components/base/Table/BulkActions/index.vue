<script lang="ts">
export default {
  name: "BaseTableBulkActions",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Collapsed from "@/shared/components/Collapsed.vue";
import {
  BtnVariantsEnum,
  BtnSizesEnum,
} from "@/shared/components/base/Btn/types";

type Props = {
  selected: string[];
};

const props = withDefaults(defineProps<Props>(), {
  selected: () => [],
});

const { t } = useI18n();

const emits = defineEmits<{
  (e: "reset"): void;
}>();

const handleClick = () => {
  emits("reset");
};
</script>

<template>
  <Collapsed
    key="base-table-bulk-actions"
    :visible="!!props.selected.length"
    class="base-table-bulk-actions"
  >
    <div class="base-table-bulk-actions__inner">
      <div
        class="base-table-bulk-actions__count"
        :class="{
          'base-table-bulk-actions__count--hide': !props.selected.length,
        }"
      >
        <span>
          {{
            t("filteredTable.labels.selected", {
              count: props.selected.length,
            })
          }}
        </span>
        <Btn
          v-tooltip="t('filteredTable.actions.unselect')"
          :size="BtnSizesEnum.SMALL"
          :variant="BtnVariantsEnum.LINK"
          inline
          @click="handleClick"
        >
          <i class="fa fa-times" />
        </Btn>
      </div>
      <div class="base-table-bulk-actions__actions">
        <slot />
      </div>
    </div>
  </Collapsed>
</template>

<style lang="scss" scoped>
@import "index";
</style>
