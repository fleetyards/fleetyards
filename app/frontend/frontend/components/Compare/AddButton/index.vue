<script lang="ts">
export default {
  name: "CompareAddButton",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  label: string;
  full?: boolean;
  fullHint?: string;
  // In the table's label rail, which a translated label would widen.
  compact?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  full: false,
  fullHint: undefined,
  compact: false,
});

const emit = defineEmits<{
  open: [];
}>();

const { t } = useI18n();

const tooltip = computed(() => {
  if (props.full) return props.fullHint;

  return props.compact ? props.label : undefined;
});
</script>

<template>
  <!-- The tooltip hangs on the wrapper, not the button: a disabled button
       dispatches no pointer events, so the one case that has something to say is
       the one that could never say it. -->
  <div v-tooltip="tooltip" class="compare-add">
    <Btn
      :disabled="full"
      :size="BtnSizesEnum.MD"
      :aria-label="label"
      data-test="compare-add"
      mobile-icon-only
      @click="emit('open')"
    >
      <i class="fa-light fa-plus" />
      {{ compact ? t("actions.add") : label }}
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
.compare-add {
  display: flex;
  align-items: center;
}
</style>
