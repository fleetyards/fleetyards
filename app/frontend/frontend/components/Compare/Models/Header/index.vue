<script lang="ts">
export default {
  name: "CompareModelsHeader",
};
</script>

<script lang="ts" setup>
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { ViewImageSizeEnum } from "@/shared/components/ViewImage/types";
import { useCompareModelFilters } from "@/frontend/composables/useCompareModelFilters";
import { useI18n } from "@/shared/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  models: Model[];
};

defineProps<Props>();

const { t } = useI18n();

const { filter, filters } = useCompareModelFilters();

const remove = (model: Model) => {
  filter({
    models: (filters.value.models || []).filter((slug) => slug !== model.slug),
  });
};
</script>

<template>
  <!-- Two sibling rows, deliberately not wrapped: `position: sticky` can only travel
       inside its parent's box, so a wrapper here would let the name row scroll away
       the moment the images did. As direct children of the matrix stack, the name row
       can stay pinned for the whole page. -->
  <div class="compare-grid">
    <div class="compare-cell compare-cell--label" />
    <div
      v-for="model in models"
      :key="model.slug"
      class="compare-cell compare-header__image-cell"
    >
      <ViewImage
        v-if="model.media.storeImage"
        :image="model.media.storeImage"
        :size="ViewImageSizeEnum.LARGE"
        :alt="model.name"
        class="compare-header__image"
      />
      <button
        v-tooltip="t('labels.compare.removeModel')"
        type="button"
        class="compare-header__remove"
        :aria-label="t('labels.compare.removeModel')"
        @click="remove(model)"
      >
        <i class="fa-light fa-times" />
      </button>
    </div>
  </div>

  <div class="compare-grid compare-header__titles">
    <div class="compare-cell compare-cell--label compare-header__count">
      {{ t("labels.compare.shipCount", { count: models.length }) }}
    </div>
    <div
      v-for="model in models"
      :key="model.slug"
      class="compare-cell compare-header__title"
    >
      <router-link :to="{ name: 'ship', params: { slug: model.slug } }">
        {{ model.name }}
      </router-link>
      <span class="compare-header__manufacturer">
        {{ model.manufacturer?.name }}
      </span>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Compare/compareGrid";

// Full-bleed store image at the old design's height — a small thumbnail lost the ship's
// silhouette, which is half of what identifies a column at a glance.
.compare-header__image-cell {
  position: relative;
  height: 242px;
  padding: 0 6px;
}

.compare-header__image {
  display: block;
  width: 100%;
  height: 100%;
  overflow: hidden;
  border-top-left-radius: $border-radius-base;
  border-top-right-radius: $border-radius-base;

  :deep(.lazy-image__img) {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
}

.compare-header__remove {
  position: absolute;
  top: 10px;
  right: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  padding: 0;
  background: $gray-darker;
  color: #fff;
  border: 0;
  border-radius: 10px 0 0 10px;
  cursor: pointer;
  transition: background 0.15s ease;

  &:hover {
    background: $danger;
  }
}

// Pinned on the vertical axis only, so the ship a column belongs to stays readable
// however far down the page you are. Below the nav's own z-index, so it never covers it.
.compare-header__titles {
  position: sticky;
  top: 0;
  z-index: 500;
  background: $gray-darker;
  border-bottom: 1px solid rgba($gray-light, 0.28);
  border-bottom-right-radius: $border-radius-base;
  border-bottom-left-radius: $border-radius-base;
}

.compare-header__count {
  align-self: center;
  font-size: 11px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.compare-header__title {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 9px 14px;
  text-align: center;

  a {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 15px;
    color: lighten($text-color, 15%);

    &:hover {
      color: $gold;
    }
  }
}

.compare-header__manufacturer {
  font-size: 11px;
  color: $gray-light;
}
</style>
