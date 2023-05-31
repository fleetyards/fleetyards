<template>
  <BtnDropdown
    :size="size"
    :variant="variant"
    :mobile-block="true"
    :inline="true"
  >
    <template #label>
      <template v-if="!mobile">{{ t("labels.pagination.perPage") }}:</template>
      {{ perPage }}
    </template>
    <Btn
      v-for="(step, index) in steps"
      :key="`per-page-drowndown-${uuid}-${index}-${step}`"
      size="small"
      variant="link"
      @click="update(step)"
    >
      {{ step }}
    </Btn>
  </BtnDropdown>
</template>

<script lang="ts" setup>
import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import type {
  Props as BtnProps,
  BtnSizes,
  BtnVariants,
} from "@/frontend/core/components/Btn/index.vue";
import { v4 as uuidv4 } from "uuid";
import { useAppStore } from "@/frontend/stores/App";
import { storeToRefs } from "pinia";
import { useI18n } from "@/frontend/composables/useI18n";

interface Props extends BtnProps {
  size: BtnSizes;
  variant: BtnVariants;
  perPage: number | "all";
  steps?: number[] | string[];
}

withDefaults(defineProps<Props>(), {
  steps: () => [10, 20, 50, 100],
});

const { t } = useI18n();

const appStore = useAppStore();

const { mobile } = storeToRefs(appStore);

const uuid = uuidv4();

const emit = defineEmits(["change"]);

const update = (step: string | number) => {
  emit("change", step);
};
</script>

<script lang="ts">
export default {
  name: "PerPageDropdown",
};
</script>
