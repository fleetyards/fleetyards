<script lang="ts">
export default {
  name: "PaintBooth",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import HoloViewer from "@/shared/components/HoloViewer/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import {
  PanelTonesEnum,
  PanelVariantsEnum,
} from "@/shared/components/base/Panel/types";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { PanelHeadingShadowEnum } from "@/shared/components/base/Panel/Heading/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { type MediaFile, type Model } from "@/services/fyApi";
import {
  ModelStateEnum,
  modelStateTexturedHolo,
} from "@/frontend/composables/useModelStates";
import { useModelHolo } from "@/frontend/composables/useModelHolo";
import { useI18n } from "@/shared/composables/useI18n";

interface Props {
  model: Model;
  // The paint's slug, or nothing for the ship's own colours.
  paint?: string;
}

const props = withDefaults(defineProps<Props>(), {
  paint: undefined,
});

const emit = defineEmits<{
  "update:paint": [slug?: string];
}>();

// Above the hull, so the top of the paint shows as it turns.
const HOLO_ELEVATION = 18;

// A three-quarter view off the nose: holos keep the game's frame, nose to -Z,
// and the viewer's default of -90 starts square on the side.
const HOLO_AZIMUTH = -135;

const { t } = useI18n();

const viewer = ref<InstanceType<typeof HoloViewer>>();

// Landed, standing on its gear on the floor, wherever that is exported
// painted.
const pose = computed(() =>
  modelStateTexturedHolo(props.model, ModelStateEnum.LANDED)
    ? ModelStateEnum.LANDED
    : ModelStateEnum.FLIGHT,
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
  () => pose.value,
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
// paint fits.
const holoUnavailable = () => {
  if (holoModel.value?.textured) texturedHolo.value = false;
};

const painted = computed(
  () => texturedHoloAvailable.value && texturedHolo.value,
);

const cardImage = (image?: MediaFile) =>
  image?.mediumUrl ?? image?.smallUrl ?? undefined;

// The ship's own colours first, then its paints, as the ship page lists them.
const cards = computed(() => [
  {
    key: "own",
    slug: undefined,
    name: t("labels.texturedHoloOwnPaint"),
    image: cardImage(props.model.media.storeImage),
    selected: !holoPaint.value,
  },
  ...holoPaints.value.map((paint) => ({
    key: paint.slug,
    slug: paint.slug,
    name: paint.name,
    image: cardImage(paint.media.storeImage),
    selected: holoPaint.value?.id === paint.id,
  })),
]);
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
        backdrop
        @unavailable="holoUnavailable"
      />
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
        <span v-if="painted" class="paint-booth__count">
          {{ holoPaints.length + 1 }}
        </span>
      </h2>
      <p
        v-if="!painted"
        class="paint-booth__note"
        data-test="paint-booth-unavailable"
      >
        {{ t("paintBooth.unavailable") }}
      </p>
      <ul v-else class="paint-booth__list" data-test="paint-booth-paints">
        <li
          v-for="card in cards"
          :key="card.key"
          class="paint-booth__item"
          :data-test="`paint-booth-paint-${card.key}`"
        >
          <Panel
            :bg-image="card.image"
            :variant="PanelVariantsEnum.SLIM"
            :tone="
              card.selected ? PanelTonesEnum.PRIMARY : PanelTonesEnum.NEUTRAL
            "
            :outer-spacing="false"
          >
            <PanelHeading
              :shadow="PanelHeadingShadowEnum.TOP"
              :level="HeadingLevelEnum.H3"
            >
              {{ card.name }}
            </PanelHeading>
          </Panel>
          <!-- Over the card rather than around it: a heading may not sit
               inside a button. -->
          <button
            type="button"
            class="paint-booth__pick"
            :aria-pressed="card.selected"
            :aria-label="card.name"
            @click="emit('update:paint', card.slug)"
          />
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

// Landscape, as a ship lies: no box of its own, the page lit by a spot
// behind the hull and a glow on the floor under its pedestal.
.paint-booth__stage {
  position: relative;
  height: min(60vh, 40rem);
  min-height: 20rem;
  border-radius: 4px;
  background:
    radial-gradient(
      ellipse 45% 12% at 50% 88%,
      rgba($primary, 0.28),
      transparent 70%
    ),
    radial-gradient(
      ellipse 60% 60% at 50% 45%,
      rgba($primary, 0.16),
      rgba($background, 0.35) 70%,
      transparent 100%
    );

  @media (min-width: $desktop-breakpoint) {
    height: min(72vh, 48rem);
  }
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
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  margin: 0 0 0.75rem;
  font-size: 1rem;
  color: $gray-lighter;
}

.paint-booth__count {
  font-size: 0.85em;
  color: $gray-light;
  font-variant-numeric: tabular-nums;
}

.paint-booth__note {
  color: $gray-lighter;
}

.paint-booth__list {
  --panel-image-height: 10rem;

  display: flex;
  flex-direction: column;
  gap: 12px;
  min-height: 0;
  margin: 0;
  // Room for the selected card's frame and focus ring at the scroll edges.
  padding: 2px 6px 2px 2px;
  overflow-y: auto;
  list-style: none;
}

.paint-booth__item {
  position: relative;
}

.paint-booth__pick {
  position: absolute;
  inset: 0;
  padding: 0;
  border: 0;
  border-radius: 12px;
  background: none;
  cursor: pointer;

  &:hover {
    background: rgba(white, 0.04);
  }

  &:focus-visible {
    outline: 2px solid $primary;
    outline-offset: 2px;
  }
}
</style>
