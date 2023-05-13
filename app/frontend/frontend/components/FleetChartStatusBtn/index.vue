<template>
  <Btn
    v-tooltip="!withLabel && t('actions.showStatusColor')"
    :aria-label="t('actions.showStatusColor')"
    :variant="variant"
    :size="size"
    :inline="inline"
    @click.native="toggleStatus"
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

<script lang="ts" setup>
import Btn from "@/frontend/core/components/Btn/index.vue";
import type {
  Props as BtnProps,
  BtnVariants,
  BtnSizes,
} from "@/frontend/core/components/Btn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/frontend/composables/useComlink";
import { useRoute } from "vue-router/composables";

interface Props extends BtnProps {
  withLabel?: boolean;
  variant?: BtnVariants;
  size?: BtnSizes;
  inline?: boolean;
}

withDefaults(defineProps<Props>(), {
  withLabel: true,
  filename: "fleetyards-screenshot",
  variant: "default",
  size: "default",
  inline: false,
});

const { t } = useI18n();

const showStatus = ref(false);

const route = useRoute();

const comlink = useComlink();

onMounted(() => {
  showStatus.value = !!route.query?.showStatus;

  comlink.$on("fleetchart-toggle-status", setShowStatus);
});

onBeforeUnmount(() => {
  comlink.$off("fleetchart-toggle-status");
});

const setShowStatus = () => {
  showStatus.value = !showStatus.value;
};

const toggleStatus = () => {
  comlink.$emit("fleetchart-toggle-status");
};
</script>

<script lang="ts">
export default {
  name: "FleetChartStatusBtn",
};
</script>
