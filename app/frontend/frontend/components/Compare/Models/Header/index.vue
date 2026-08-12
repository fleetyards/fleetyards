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
  <div class="compare-header">
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
          :size="ViewImageSizeEnum.MEDIUM"
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

    <!-- Only the name bar sticks: keeping the images pinned too would cost a
         third of the viewport on a page that is mostly vertical scrolling. -->
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
  </div>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Compare/compareGrid";

.compare-header__image-cell {
  position: relative;
  padding: 0 6px;
}

.compare-header__image {
  display: block;
  width: 100%;
  height: 120px;
  border-radius: $border-radius-base;
  overflow: hidden;

  :deep(img) {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
}

.compare-header__remove {
  position: absolute;
  top: 6px;
  right: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  padding: 0;
  background: rgba(#000, 0.65);
  color: #fff;
  border: 1px solid rgba($gray-light, 0.4);
  border-radius: 50%;
  cursor: pointer;
  transition: all 0.15s ease;

  &:hover {
    background: $danger;
    border-color: $danger;
  }
}

.compare-header__titles {
  position: sticky;
  top: 0;
  z-index: 500;
  background: $gray-darker;
  border-bottom: 1px solid rgba($gray-light, 0.28);
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
    font-size: 14px;
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
