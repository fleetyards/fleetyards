<script lang="ts">
export default {
  name: "PerPageDropdown",
};
</script>

<script lang="ts" setup>
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  perPage?: number | string;
  steps?: (number | string)[];
  size?: BtnSizesEnum;
  variant?: BtnVariantsEnum;
  inGroup?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  perPage: undefined,
  steps: () => [10, 20, 50, 100],
  size: BtnSizesEnum.DEFAULT,
  variant: BtnVariantsEnum.DEFAULT,
  inGroup: false,
});

const internalValue = ref(props.perPage || props.steps[0]);

watch(
  () => props.perPage,
  () => {
    if (props.perPage) {
      internalValue.value = props.perPage;
    }
  },
);

const mobile = useMobile();

const { t } = useI18n();

const uuid = ref(uuidv4());

onMounted(() => {
  uuid.value = uuidv4();
});

const emit = defineEmits(["change"]);

const update = (step: number | string) => {
  emit("change", step);
};
</script>

<template>
  <BtnDropdown :size="size" :variant="variant" mobile-block inline>
    <template #label>
      <template v-if="!mobile">{{ t("paginator.labels.perPage") }}:</template>
      {{ internalValue }}
    </template>
    <Btn
      v-for="(step, index) in steps"
      :key="`per-page-drowndown-${uuid}-${index}-${step}`"
      :size="BtnSizesEnum.SMALL"
      :active="step === internalValue"
      @click="update(step)"
    >
      {{ step }}
    </Btn>
  </BtnDropdown>
</template>
