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

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import type {
  BtnVariants,
  BtnSizes,
} from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import type { SpinnerAlignment } from "@/shared/components/SmallLoader/index.vue";
import type { RouteLocationRaw } from "vue-router";

type Props = {
  withLabel?: boolean;
  variant?: BtnVariants;
  size?: BtnSizes;
  inline?: boolean;
  url: string;
  title: string;
  to?: RouteLocationRaw;
  href?: string;
  type?: "button" | "submit";
  loading?: boolean;
  spinner?: boolean | SpinnerAlignment;
  exact?: boolean;
  block?: boolean;
  mobileBlock?: boolean;
  textInline?: boolean;
  active?: boolean;
  disabled?: boolean;
  routeActiveClass?: string;
  inGroup?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabel: true,
  filename: "fleetyards-screenshot",
  variant: "default",
  size: "default",
  inline: false,
  to: undefined,
  href: undefined,
  type: "button",
  loading: false,
  spinner: false,
  exact: false,
  block: false,
  mobileBlock: false,
  textInline: false,
  active: false,
  disabled: false,
  routeActiveClass: undefined,
  inGroup: false,
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

<script lang="ts">
export default {
  name: "FleetChartStatusBtn",
};
</script>
