<script lang="ts">
export default {
  name: "ModelHoloPaintMenu",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  paints: { id: string; name: string }[];
  expandLeft?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  expandLeft: false,
});

// Unset is the ship's own paint.
const paintId = defineModel<string | undefined>();

const { t } = useI18n();

const paint = computed(() =>
  props.paints.find((option) => option.id === paintId.value),
);
</script>

<template>
  <BtnDropdown expand-bottom :expand-left="expandLeft">
    <template #label>
      <span>{{ paint?.name ?? t("labels.texturedHoloOwnPaint") }}</span>
      <i class="fa-light fa-chevron-down" />
    </template>
    <Btn :active="!paint" @click="paintId = undefined">
      {{ t("labels.texturedHoloOwnPaint") }}
    </Btn>
    <Btn
      v-for="option in paints"
      :key="option.id"
      :active="paint?.id === option.id"
      @click="paintId = option.id"
    >
      {{ option.name }}
    </Btn>
  </BtnDropdown>
</template>
