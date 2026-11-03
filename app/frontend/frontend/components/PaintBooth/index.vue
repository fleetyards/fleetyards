<script lang="ts">
export default {
  name: "PaintBooth",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import HoloViewer from "@/shared/components/HoloViewer/index.vue";
import { type Model } from "@/services/fyApi";
import {
  ModelStateEnum,
  modelStateTexturedHolo,
} from "@/frontend/composables/useModelStates";
import { useModelHolo } from "@/frontend/composables/useModelHolo";
import { useI18n } from "@/shared/composables/useI18n";

interface Props {
  model: Model;
  pose: ModelStateEnum;
  // The paint's slug, or nothing for the ship's own colours.
  paint?: string;
}

const props = withDefaults(defineProps<Props>(), {
  paint: undefined,
});

const emit = defineEmits<{
  "update:pose": [pose: ModelStateEnum];
  "update:paint": [slug?: string];
}>();

// Above the hull, so the top of the paint shows as it turns.
const HOLO_ELEVATION = 18;

// A three-quarter view off the nose: holos keep the game's frame, nose to -Z,
// and the viewer's default of -90 starts square on the side.
const HOLO_AZIMUTH = -135;

const { t } = useI18n();

const viewer = ref<InstanceType<typeof HoloViewer>>();

const poses = computed(() =>
  [ModelStateEnum.FLIGHT, ModelStateEnum.LANDED].filter(
    (state) => !!modelStateTexturedHolo(props.model, state),
  ),
);

const activePose = computed(() =>
  poses.value.includes(props.pose) ? props.pose : poses.value[0],
);

const {
  texturedHolo,
  texturedHoloAvailable,
  holoPaints,
  holoPaintId,
  holoPaint,
  holoModel,
} = useModelHolo(
  () => props.model,
  () => activePose.value ?? ModelStateEnum.FLIGHT,
  { textured: true },
);

// The address names a paint by slug, the holo by id: the paints arrive after
// the ship, so the slug is matched again once they do.
watchEffect(() => {
  holoPaintId.value = holoPaints.value.find(
    (paint) => paint.slug === props.paint,
  )?.id;
});

// A textured holo that will not draw falls back to the plain one, which no
// paint fits. The other pose has an export of its own, so it gets a try.
const holoUnavailable = () => {
  if (holoModel.value?.textured) texturedHolo.value = false;
};

watch(activePose, () => {
  texturedHolo.value = true;
});

const painted = computed(
  () => texturedHoloAvailable.value && texturedHolo.value,
);

const ownImage = computed(() => props.model.media.storeImage?.smallUrl);
</script>

<template>
  <div class="paint-booth">
    <div class="paint-booth__stage" data-test="paint-booth-stage">
      <HoloViewer
        v-if="holoModel"
        ref="viewer"
        :key="holoModel.path"
        :models="[holoModel]"
        :azimuth="HOLO_AZIMUTH"
        :elevation="HOLO_ELEVATION"
        :contain-padding="1.1"
        :auto-rotate="false"
        contain
        zoomable
        turntable
        grid
        @unavailable="holoUnavailable"
      />
      <BtnGroup
        v-if="poses.length > 1"
        segmented
        class="paint-booth__poses"
        data-test="paint-booth-poses"
      >
        <Btn
          v-for="pose in poses"
          :key="pose"
          :size="BtnSizesEnum.SM"
          :active="activePose === pose"
          :data-test="`paint-booth-pose-${pose}`"
          @click="emit('update:pose', pose)"
        >
          {{ t(`labels.model.state.${pose}`) }}
        </Btn>
      </BtnGroup>
      <Btn
        :size="BtnSizesEnum.SM"
        class="paint-booth__fullscreen"
        :aria-label="t('actions.vehicleOverview.fullscreenHolo')"
        v-tooltip="t('actions.vehicleOverview.fullscreenHolo')"
        data-test="paint-booth-fullscreen"
        @click="viewer?.enableFullscreen()"
      >
        <i class="fa-light fa-expand" />
      </Btn>
    </div>

    <aside class="paint-booth__paints">
      <h2 class="paint-booth__title">
        {{ t("paintBooth.paints") }}
      </h2>
      <p
        v-if="!painted"
        class="paint-booth__note"
        data-test="paint-booth-unavailable"
      >
        {{ t("paintBooth.unavailable") }}
      </p>
      <ul v-else class="paint-booth__list" data-test="paint-booth-paints">
        <li>
          <button
            type="button"
            class="paint-booth__paint"
            :class="{ 'paint-booth__paint--active': !holoPaint }"
            :aria-pressed="!holoPaint"
            data-test="paint-booth-paint-own"
            @click="emit('update:paint', undefined)"
          >
            <img
              v-if="ownImage"
              :src="ownImage"
              alt=""
              loading="lazy"
              class="paint-booth__image"
            />
            <span class="paint-booth__name">
              {{ t("labels.texturedHoloOwnPaint") }}
            </span>
          </button>
        </li>
        <li v-for="paint in holoPaints" :key="paint.id">
          <button
            type="button"
            class="paint-booth__paint"
            :class="{
              'paint-booth__paint--active': holoPaint?.id === paint.id,
            }"
            :aria-pressed="holoPaint?.id === paint.id"
            :data-test="`paint-booth-paint-${paint.slug}`"
            @click="emit('update:paint', paint.slug)"
          >
            <img
              v-if="paint.media.storeImage?.smallUrl"
              :src="paint.media.storeImage.smallUrl"
              alt=""
              loading="lazy"
              class="paint-booth__image"
            />
            <span class="paint-booth__name">{{ paint.name }}</span>
          </button>
        </li>
      </ul>
    </aside>
  </div>
</template>

<style lang="scss" scoped>
.paint-booth {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 1.5rem;

  @media (min-width: $desktop-breakpoint) {
    grid-template-columns: minmax(0, 1fr) minmax(18rem, 24rem);
    align-items: start;
  }
}

// Landscape, as a ship lies. The canvas is transparent, so the black is
// the stage's own.
.paint-booth__stage {
  position: relative;
  height: min(60vh, 40rem);
  min-height: 20rem;
  overflow: hidden;
  border-radius: 4px;
  background: black;

  @media (min-width: $desktop-breakpoint) {
    height: min(72vh, 48rem);
  }
}

.paint-booth__poses {
  position: absolute;
  top: 8px;
  left: 8px;
}

.paint-booth__fullscreen {
  position: absolute;
  top: 8px;
  right: 8px;
}

.paint-booth__paints {
  display: flex;
  flex-direction: column;
  min-height: 0;

  @media (min-width: $desktop-breakpoint) {
    max-height: min(72vh, 48rem);
  }
}

.paint-booth__title {
  margin: 0 0 0.75rem;
  font-size: 1rem;
  color: $gray-lighter;
}

.paint-booth__note {
  color: $gray-lighter;
}

.paint-booth__list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(9rem, 1fr));
  gap: 0.5rem;
  margin: 0;
  padding: 0;
  overflow-y: auto;
  list-style: none;
}

.paint-booth__paint {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  padding: 0;
  overflow: hidden;
  border: 1px solid $gray-black-hover;
  border-radius: 4px;
  background: rgba($background, 0.5);
  color: inherit;
  text-align: left;
  cursor: pointer;

  &:hover,
  &:focus-visible {
    border-color: $gray-light;
  }
}

.paint-booth__paint--active,
.paint-booth__paint--active:hover,
.paint-booth__paint--active:focus-visible {
  border-color: $primary;
  box-shadow: 0 0 0 1px $primary;
}

.paint-booth__image {
  width: 100%;
  aspect-ratio: 16 / 9;
  object-fit: cover;
}

.paint-booth__name {
  padding: 0.375rem 0.5rem;
  font-size: 0.85em;
  line-height: 1.3;
}
</style>
