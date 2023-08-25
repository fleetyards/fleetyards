<template>
  <div class="row fleetchart-list">
    <div class="col-12 fleetchart-wrapper">
      <div class="fleetchart-controls">
        <Starship42Btn v-if="!mobile" size="small" :items="items" />

        <BtnDropdown size="small">
          <template #label>
            <template v-if="!mobile">
              {{ t("labels.fleetchartApp.viewpoint") }}:
            </template>
            {{ t(`labels.fleetchartApp.viewpointOptions.${viewpoint}`) }}
          </template>
          <Btn
            v-for="(option, index) in FleetchartViewpoints"
            :key="`fleetchart-screen-height-drowndown-${index}-${option}`"
            size="small"
            variant="link"
            :active="viewpoint === option"
            @click="setViewpoint(option)"
          >
            {{ t(`labels.fleetchartApp.viewpointOptions.${option}`) }}
          </Btn>
        </BtnDropdown>

        <Btn size="small" :active="gridEnabled" @click="toggleGrid">
          <i class="fad fa-th" />
        </Btn>

        <BtnDropdown size="small">
          <template v-if="downloadName">
            <DownloadScreenshotBtn
              element="#fleetchart"
              :filename="downloadName"
              size="small"
              variant="dropdown"
            />

            <hr />
          </template>

          <Starship42Btn
            v-if="mobile"
            :items="items"
            size="small"
            variant="dropdown"
            :with-icon="true"
          />

          <Btn size="small" variant="dropdown" @click="toggleLabels">
            <i class="fad fa-tags" />
            <span v-if="showLabels">
              {{ t("actions.hideLabels") }}
            </span>
            <span v-else>
              {{ t("actions.showLabels") }}
            </span>
          </Btn>

          <FleetChartStatusBtn variant="dropdown" size="small" />
        </BtnDropdown>
      </div>

      <div
        class="fleetchart-grid-label"
        :class="{
          'fleetchart-grid-enabled': gridEnabled,
        }"
      >
        {{ t("labels.fleetchartApp.gridSize", { size: gridSizeLabel }) }}
      </div>

      <div class="fleetchart-scroll-wrapper">
        <transition-group
          id="fleetchart"
          name="fade-list"
          :appear="true"
          tag="div"
          class="fleetchart"
        >
          <FleetchartItem
            v-for="item in items"
            :key="item.id"
            :item="item"
            :viewpoint="viewpoint"
            :show-label="showLabels"
            :show-status="showStatus"
            :size-multiplicator="sizeMultiplicator"
            :scale="scale"
          />
          <div
            key="made-by-the-community"
            class="fleetchart-item fade-list-item fleetchart-download-image"
          >
            <CommunityLogo />
          </div>
        </transition-group>
        <canvas
          ref="fleetchartGrid"
          class="fleetchart-grid"
          :class="{
            'fleetchart-grid-enabled': gridEnabled,
          }"
          :width="screenWidth"
          :height="screenHeight"
        />
      </div>

      <FleetchartSlider
        v-model="internalScale"
        :min-scale="minScale"
        :max-scale="maxScale"
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import FleetchartSlider from "@/frontend/components/Fleetchart/Slider/index.vue";
import Btn from "@/shared/components/BaseBtn/index.vue";
import BtnDropdown from "@/shared/components/BaseBtnDropdown/index.vue";
import DownloadScreenshotBtn from "@/frontend/components/DownloadScreenshotBtn/index.vue";
import FleetChartStatusBtn from "@/frontend/components/FleetChartStatusBtn/index.vue";
import Starship42Btn from "@/frontend/components/Starship42Btn/index.vue";
import CommunityLogo from "@/shared/components/CommunityLogo/index.vue";
import FleetchartItem from "./Item/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  FleetchartViewpoints,
  useFleetchartStore,
} from "@/shared/stores/fleetchart";
import { Vehicle, Model } from "@/services/fyApi";

type Props = {
  namespace: string;
  items?: Vehicle[] | Model[];
  myShip?: boolean;
  downloadName?: string;
};

const props = withDefaults(defineProps<Props>(), {
  items: () => [],
  myShip: false,
  downloadName: undefined,
});

const { t } = useI18n();

const showStatus = ref(false);

const gridEnabled = ref(false);

const screenWidth = ref<number | undefined>();

const screenHeight = ref<number | undefined>();

const gridSize = 80.0;

const sizeMultiplicator = 4;

const internalScale = ref(1);

const maxScale = 20;

const minScale = 0.5;

const mobile = useMobile();

const gridSizeLabel = computed(() => {
  return (gridSize / scale.value / sizeMultiplicator)
    .toFixed(2)
    .replace(".00", "");
});

const fleetchartStore = useFleetchartStore();

const scale = computed(() => {
  return fleetchartStore.fleetchartScale(props.namespace);
});

const viewpoint = computed(() => {
  return fleetchartStore.fleetchartViewpoint(props.namespace);
});

const showLabels = computed(() => {
  return fleetchartStore.showLabels(props.namespace);
});

watch(
  () => internalScale.value,
  () => {
    fleetchartStore.updateScale({
      namespace: props.namespace,
      scale: internalScale.value,
    });
  },
);

const comlink = useComlink();

const route = useRoute();

onMounted(() => {
  internalScale.value = scale.value;

  showStatus.value = !!route.query?.showStatus;

  comlink.on("fleetchart-toggle-status", toggleStatus);

  updateScreenSize();

  window.addEventListener("resize", updateScreenSize);
  window.addEventListener("deviceorientation", updateScreenSize);
});

onUnmounted(() => {
  comlink.off("fleetchart-toggle-status");

  window.removeEventListener("resize", updateScreenSize);
  window.removeEventListener("deviceorientation", updateScreenSize);
});

const updateScreenSize = () => {
  screenWidth.value = window.innerWidth;
  screenHeight.value = window.innerHeight;

  drawGridLines();
};

const toggleGrid = () => {
  gridEnabled.value = !gridEnabled.value;

  drawGridLines();
};

const setViewpoint = (viewpoint: FleetchartViewpoints) => {
  fleetchartStore.updateViewpoint({
    namespace: props.namespace,
    viewpoint,
  });
};

const toggleStatus = () => {
  showStatus.value = !showStatus.value;
};

const toggleLabels = () => {
  fleetchartStore.toggleLabels(props.namespace);
};

const fleetchartGrid = ref<HTMLCanvasElement>();

const drawGridLines = async () => {
  if (!gridEnabled.value) {
    return;
  }

  await nextTick();

  const canvas = fleetchartGrid.value;

  if (!canvas) {
    return;
  }

  if (canvas.getContext) {
    const ctx = canvas.getContext("2d");

    if (!ctx) {
      return;
    }

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const drawVerticalLine = (
      left: number,
      top: number,
      height: number,
      color: string | CanvasGradient | CanvasPattern,
    ) => {
      ctx.fillStyle = color;
      ctx.fillRect(left, top, 1, height);
    };

    const drawHorizontalLine = (
      left: number,
      top: number,
      width: number,
      color: string | CanvasGradient | CanvasPattern,
    ) => {
      ctx.fillStyle = color;
      ctx.fillRect(left, top, width, 1);
    };

    const lineColor = "rgba(255, 255, 255, 0.5)";

    for (let i = 0; i < canvas.width; i += gridSize) {
      drawVerticalLine(i, 0, canvas.height, lineColor);
    }

    for (let i = 0; i < canvas.height; i += gridSize) {
      drawHorizontalLine(0, i, canvas.width, lineColor);
    }
  }
};
</script>

<script lang="ts">
export default {
  name: "FleetchartList",
};
</script>
