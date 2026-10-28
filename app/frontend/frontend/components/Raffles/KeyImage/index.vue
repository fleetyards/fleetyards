<script lang="ts">
export default {
  name: "RaffleKeyImage",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import { type MediaFile } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  images: MediaFile[];
  title: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const index = ref(0);

const count = computed(() => props.images.length);

const show = (target: number) => {
  index.value = (target + count.value) % count.value;
};

// A swipe is a horizontal drag of more than this; anything shorter is a tap.
const SWIPE = 40;
let touchStartX: number | undefined;

const onTouchStart = (event: TouchEvent) => {
  touchStartX = event.touches[0]?.clientX;
};

const onTouchEnd = (event: TouchEvent) => {
  if (touchStartX === undefined) return;

  const delta = (event.changedTouches[0]?.clientX ?? touchStartX) - touchStartX;
  touchStartX = undefined;

  if (Math.abs(delta) < SWIPE) return;
  show(index.value + (delta < 0 ? 1 : -1));
};

const imageUrl = (image: MediaFile) =>
  image.xlargeUrl || image.largeUrl || image.url;
</script>

<template>
  <Panel class="raffle-key" data-test="raffle-gallery">
    <div
      class="raffle-key__viewport"
      role="region"
      :aria-roledescription="t('raffles.slider.label')"
      :aria-label="props.title"
      @touchstart.passive="onTouchStart"
      @touchend="onTouchEnd"
    >
      <div
        class="raffle-key__track"
        :style="{ transform: `translateX(-${index * 100}%)` }"
      >
        <img
          v-for="(image, imageIndex) in props.images"
          :key="image.signedId || imageIndex"
          :src="imageUrl(image)"
          :alt="props.title"
          :aria-hidden="imageIndex !== index"
          class="raffle-key__image"
        />
      </div>
      <template v-if="count > 1">
        <button
          type="button"
          class="raffle-key__arrow raffle-key__arrow--prev"
          :aria-label="t('raffles.slider.previous')"
          data-test="raffle-gallery-prev"
          @click="show(index - 1)"
        >
          <i class="fa-light fa-chevron-left" />
        </button>
        <button
          type="button"
          class="raffle-key__arrow raffle-key__arrow--next"
          :aria-label="t('raffles.slider.next')"
          data-test="raffle-gallery-next"
          @click="show(index + 1)"
        >
          <i class="fa-light fa-chevron-right" />
        </button>
      </template>
      <div v-if="count > 1" class="raffle-key__dots">
        <button
          v-for="(image, dotIndex) in props.images"
          :key="image.signedId || dotIndex"
          type="button"
          class="raffle-key__dot"
          :class="{ 'raffle-key__dot--active': dotIndex === index }"
          :aria-label="t('raffles.showImage', { index: dotIndex + 1 })"
          :aria-current="dotIndex === index"
          @click="show(dotIndex)"
        />
      </div>
    </div>
  </Panel>
</template>

<style lang="scss" scoped>
.raffle-key {
  overflow: hidden;
}

.raffle-key__viewport {
  position: relative;
  overflow: hidden;
}

.raffle-key__track {
  display: flex;
  transition: transform 0.35s ease;

  @media (prefers-reduced-motion: reduce) {
    transition: none;
  }
}

.raffle-key__image {
  display: block;
  flex: 0 0 100%;
  width: 100%;
  aspect-ratio: 16 / 5.95;
  object-fit: cover;
}

.raffle-key__arrow {
  position: absolute;
  top: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  transform: translateY(-50%);
  border: 1px solid var(--color-edge, rgba(122, 130, 136, 0.5));
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.55);
  color: var(--color-lifted, #eee);
  cursor: pointer;

  &:hover {
    background: rgba(0, 0, 0, 0.75);
  }
}

.raffle-key__arrow--prev {
  left: 12px;
}

.raffle-key__arrow--next {
  right: 12px;
}

.raffle-key__dots {
  position: absolute;
  bottom: 12px;
  left: 50%;
  display: flex;
  gap: 8px;
  padding: 6px 10px;
  transform: translateX(-50%);
  border-radius: 999px;
  background: rgba(0, 0, 0, 0.55);
}

.raffle-key__dot {
  width: 8px;
  height: 8px;
  padding: 0;
  border: 0;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.45);
  cursor: pointer;

  // The visible dot is small; the hit area is not.
  box-shadow: 0 0 0 10px transparent;
}

.raffle-key__dot--active {
  background: var(--color-primary, #428bca);
}
</style>
