<script lang="ts">
export default {
  name: "FleetChartStatusBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

type Props = {
  withLabel?: boolean;
  variant?: `${BtnVariantsEnum}`;
  size?: `${BtnSizesEnum}`;
  inline?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabel: true,
  variant: BtnVariantsEnum.DEFAULT,
  size: BtnSizesEnum.DEFAULT,
  inline: false,
});

const { t } = useI18n();

const showStatus = ref(false);

const route = useRoute();

const comlink = useComlink();

const tooltip = computed(() => {
  if (props.withLabel) {
    return undefined;
  }

  return t("actions.showStatusColor");
});

onMounted(() => {
  showStatus.value = !!route.query?.showStatus;

  comlink.on("fleetchart-toggle-status", setShowStatus);
});

onBeforeUnmount(() => {
  comlink.off("fleetchart-toggle-status");
});

const setShowStatus = () => {
  showStatus.value = !showStatus.value;
};

const toggleStatus = () => {
  comlink.emit("fleetchart-toggle-status");
};
</script>

<template>
  <Btn
    v-tooltip="tooltip"
    :aria-label="t('actions.showStatusColor')"
    :variant="variant"
    :size="size"
    :inline="inline"
    @click="toggleStatus"
  >
    <i
      class="fad"
      :class="{
        'fa-star-half-alt': !showStatus,
        'fa-star': showStatus,
      }"
    />
    <span v-if="withLabel">
      <template v-if="showStatus">
        {{ t("actions.hideStatusColor") }}
      </template>
      <template v-else>
        {{ t("actions.showStatusColor") }}
      </template>
    </span>
  </Btn>
</template>
