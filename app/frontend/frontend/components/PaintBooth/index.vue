<script lang="ts">
export default {
  name: "PaintBooth",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import HoloViewer from "@/shared/components/HoloViewer/index.vue";
import PickerCard from "@/shared/components/PickerCard/index.vue";
import StageLayout from "@/frontend/components/StageLayout/index.vue";
import StagePanel from "@/frontend/components/StagePanel/index.vue";
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

// Folded down to the paint on the ship, leaving the stage to it.
const collapsed = ref(false);

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

// What the folded card still says: the paint on the ship.
const selectedName = computed(
  () => cards.value.find((card) => card.selected)?.name,
);
</script>

<template>
  <StageLayout
    landscape
    class="paint-booth"
    :controls-label="t('dressingRoom.viewControls')"
    data-test="paint-booth-stage"
  >
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
    <!-- A ship painted only, whose painted holo failed, has no plain one to
         fall back to. -->
    <div v-else class="paint-booth__no-holo" data-test="paint-booth-no-holo">
      <i class="fa-duotone fa-cube" />
      <p>{{ t("paintBooth.unavailable") }}</p>
    </div>

    <template #controls>
      <slot name="controls" />
      <Btn
        v-if="holoModel"
        :aria-label="t('actions.vehicleOverview.fullscreenHolo')"
        v-tooltip="t('actions.vehicleOverview.fullscreenHolo')"
        data-test="paint-booth-fullscreen"
        @click="viewer?.enableFullscreen()"
      >
        <i class="fa-light fa-expand" />
      </Btn>
    </template>

    <template #end>
      <StagePanel>
        <section class="paint-booth__paints">
          <h2 class="paint-booth__title">
            <button
              v-if="painted"
              type="button"
              class="paint-booth__toggle"
              :aria-expanded="!collapsed"
              aria-controls="paint-booth-paints"
              data-test="paint-booth-toggle"
              @click="collapsed = !collapsed"
            >
              {{ t("paintBooth.paints") }}
              <span class="paint-booth__count">
                {{ holoPaints.length + 1 }}
              </span>
              <i
                class="fa-light fa-chevron-up paint-booth__chevron"
                :class="{ 'paint-booth__chevron--collapsed': collapsed }"
                aria-hidden="true"
              />
            </button>
            <template v-else>{{ t("paintBooth.paints") }}</template>
          </h2>
          <p
            v-if="!painted"
            class="paint-booth__note"
            data-test="paint-booth-unavailable"
          >
            {{ t("paintBooth.unavailable") }}
          </p>
          <template v-else>
            <p
              v-if="collapsed"
              class="paint-booth__collapsed"
              data-test="paint-booth-collapsed"
            >
              {{ selectedName }}
            </p>
            <ul
              v-show="!collapsed"
              id="paint-booth-paints"
              class="paint-booth__list"
              data-test="paint-booth-paints"
            >
              <li
                v-for="card in cards"
                :key="card.key"
                :data-test="`paint-booth-paint-${card.key}`"
              >
                <PickerCard
                  :name="card.name"
                  :image="card.image"
                  :selected="card.selected"
                  @toggle="emit('update:paint', card.slug)"
                />
              </li>
            </ul>
          </template>
        </section>
      </StagePanel>
    </template>
  </StageLayout>
</template>

<style lang="scss" scoped>
.paint-booth__no-holo {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  height: 100%;
  padding: 1rem;
  color: $gray-lighter;
  text-align: center;

  i {
    font-size: 4rem;
    opacity: 0.4;
  }
}

.paint-booth__paints {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.paint-booth__title {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  margin: 0;
  color: $gray-lighter;
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.paint-booth__toggle {
  display: flex;
  flex: 1;
  align-items: center;
  gap: 0.5rem;
  min-height: $tap-target-min;
  padding: 0;
  border: 0;
  background: none;
  color: inherit;
  font: inherit;
  letter-spacing: inherit;
  text-transform: inherit;
  cursor: pointer;

  &:hover,
  &:focus-visible {
    color: $text-color;
  }
}

.paint-booth__chevron {
  margin-left: auto;
  transition: transform 0.15s ease;
}

.paint-booth__chevron--collapsed {
  transform: rotate(180deg);
}

.paint-booth__collapsed {
  margin: 0;
  color: var(--color-lifted);
  font-weight: 600;
}

.paint-booth__count {
  color: $gray-light;
  font-variant-numeric: tabular-nums;
  letter-spacing: normal;
}

.paint-booth__note {
  margin: 0;
  color: $gray-lighter;
}

// A paint is judged on the ship, so picking one must not scroll the ship away:
// a strip under the stage on a phone, a two-column grid beside it on a desktop.
.paint-booth__list {
  display: flex;
  gap: 10px;
  margin: 0;
  padding: 0 0 6px;
  overflow-x: auto;
  list-style: none;
  scroll-snap-type: x proximity;

  > li {
    flex: 0 0 12rem;
    scroll-snap-align: start;
  }

  @media (min-width: $desktop-breakpoint) {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    align-content: start;
    padding: 0;
    overflow: visible;
    scroll-snap-type: none;
  }
}
</style>
