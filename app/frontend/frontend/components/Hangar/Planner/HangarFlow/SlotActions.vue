<script lang="ts">
export default {
  name: "HangarPlannerHangarFlowSlotActions",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

const emit = defineEmits<{
  edit: [];
  copy: [];
  remove: [];
}>();

const { t } = useI18n();
</script>

<template>
  <span class="hangar-flow-slot-actions">
    <Btn
      :size="BtnSizesEnum.XS"
      :variant="BtnVariantsEnum.BARE"
      :aria-label="t('hangarPlanner.editSlot')"
      :title="t('hangarPlanner.editSlot')"
      data-test="hangar-plan-flow-slot-edit"
      @click="emit('edit')"
    >
      <i class="fa-light fa-pen" aria-hidden="true" />
    </Btn>
    <Btn
      :size="BtnSizesEnum.XS"
      :variant="BtnVariantsEnum.BARE"
      :aria-label="t('hangarPlanner.copySlot')"
      :title="t('hangarPlanner.copySlot')"
      data-test="hangar-plan-flow-slot-copy"
      @click="emit('copy')"
    >
      <i class="fa-light fa-copy" aria-hidden="true" />
    </Btn>
    <Btn
      :size="BtnSizesEnum.XS"
      :variant="BtnVariantsEnum.BARE"
      :tone="BtnTonesEnum.DANGER"
      :aria-label="t('hangarPlanner.removeSlot')"
      :title="t('hangarPlanner.removeSlot')"
      :confirm="t('hangarPlanner.confirmRemoveSlot')"
      data-test="hangar-plan-flow-slot-remove"
      @click="emit('remove')"
    >
      <i class="fa-light fa-trash" aria-hidden="true" />
    </Btn>
  </span>
</template>

<style lang="scss" scoped>
.hangar-flow-slot-actions {
  display: inline-flex;
  flex: none;
  gap: 2px;
  align-items: center;
  margin-left: auto;
}
</style>
