<template>
  <BtnDropdown
    :size="size"
    :variant="variant"
    :mobile-block="true"
    :inline="true"
    :in-group="inGroup"
  >
    <template #label>
      <template v-if="!mobile"
        >{{ i18n?.t("paginator.labels.perPage") }}:</template
      >
      {{ internalValue }}
    </template>
    <Btn
      v-for="(step, index) in steps"
      :key="`per-page-drowndown-${uuid}-${index}-${step}`"
      size="small"
      variant="dropdown"
      :active="step === internalValue"
      @click="update(step)"
    >
      {{ step }}
    </Btn>
  </BtnDropdown>
</template>

<script lang="ts" setup>
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import type {
  BtnSizes,
  BtnVariants,
} from "@/shared/components/base/Btn/index.vue";
import { v4 as uuidv4 } from "uuid";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

type Props = {
  perPage?: number | string;
  steps?: (number | string)[];
  size?: BtnSizes;
  variant?: BtnVariants;
  inGroup?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  perPage: undefined,
  steps: () => [10, 20, 50, 100],
  size: "default",
  variant: "default",
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

const i18n = inject<I18nPluginOptions>("i18n");

const uuid = ref(uuidv4());

onMounted(() => {
  uuid.value = uuidv4();
});

const emit = defineEmits(["change"]);

const update = (step: number | string) => {
  emit("change", step);
};
</script>

<script lang="ts">
export default {
  name: "PerPageDropdown",
};
</script>
