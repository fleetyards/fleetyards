<script lang="ts">
export default {
  name: "ModuleSelectModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ModelModule,
} from "@/services/fyApi";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";

import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";

type Props = {
  modules: ModelModule[];
  selectedModuleSlug?: string;
  onSelect: (mod: ModelModule | null) => void;
};

const props = defineProps<Props>();

const { t } = useI18n();

const comlink = useComlink();

const { supported: webpSupported } = useWebpCheck();

const storeImage = (mod: ModelModule) =>
  mod.media.storeImage?.smallUrl ||
  (webpSupported.value ? fallbackImage : fallbackImageJpg);

// Ports that say nothing about what the module is for. The slot row drops the
// same two from its own expansion.
const UNINFORMATIVE: HardpointCategoryEnum[] = [
  HardpointCategoryEnum.CONTROLLER,
  HardpointCategoryEnum.UNKNOWN,
];

// What the module brings, which is the whole reason to pick one over another: a
// torpedo bay and a cargo bay fill the same slot and ship the same photograph,
// and only their fittings tell them apart. The count is dropped at one, because
// every category label is already plural.
const contents = (mod: ModelModule): string => {
  const counts = new Map<string, number>();

  (mod.hardpoints || []).forEach((hardpoint: Hardpoint) => {
    const category = hardpoint.category;

    if (!category || UNINFORMATIVE.includes(category)) {
      return;
    }

    counts.set(category, (counts.get(category) || 0) + 1);
  });

  if (!counts.size) {
    return t("labels.hardpoint.moduleContentsUnknown");
  }

  return [...counts.entries()]
    .map(([category, count]) => {
      const label = t(`labels.hardpoint.categories.${category}`);

      return count > 1 ? `${count} × ${label}` : label;
    })
    .join(" · ");
};

const cargo = (mod: ModelModule): number => mod.metrics?.cargo || 0;

// Only a status worth a warning is shown. Most modules are flight ready, and a
// pill on every row would say nothing while crowding the figures that do.
const upcoming = (mod: ModelModule): boolean =>
  !!mod.productionStatus && mod.productionStatus !== "flight-ready";

const selectModule = (mod: ModelModule) => {
  props.onSelect(mod);
  comlink.emit("close-modal");
};

const clearModule = () => {
  props.onSelect(null);
  comlink.emit("close-modal");
};

const isSelected = (mod: ModelModule) => mod.slug === props.selectedModuleSlug;
</script>

<template>
  <Modal :title="t('labels.hardpoint.selectModule')">
    <div class="module-options">
      <button
        type="button"
        class="module-option"
        :class="{ 'module-option--selected': !selectedModuleSlug }"
        data-test="module-option-stock"
        @click="clearModule"
      >
        <span class="module-option__image module-option__image--stock">
          <i class="fa-duotone fa-layer-minus" />
        </span>
        <span class="module-option__body">
          <span class="module-option__name">
            {{ t("labels.hardpoint.moduleStock") }}
          </span>
          <span class="module-option__contents">
            {{ t("labels.hardpoint.moduleStockHint") }}
          </span>
        </span>
        <span class="module-option__meta">
          <Pill v-if="!selectedModuleSlug" :variant="PillVariantsEnum.SUCCESS">
            <i class="fa fa-check" />
            {{ t("labels.hardpoint.moduleFitted") }}
          </Pill>
        </span>
      </button>

      <button
        v-for="mod in modules"
        :key="mod.id"
        type="button"
        class="module-option"
        :class="{ 'module-option--selected': isSelected(mod) }"
        data-test="module-option"
        @click="selectModule(mod)"
      >
        <img
          :src="storeImage(mod)"
          :alt="mod.name"
          class="module-option__image"
          loading="lazy"
        />
        <span class="module-option__body">
          <span class="module-option__name">{{ mod.name }}</span>
          <span class="module-option__contents">{{ contents(mod) }}</span>
        </span>
        <span class="module-option__meta">
          <Pill v-if="isSelected(mod)" :variant="PillVariantsEnum.SUCCESS">
            <i class="fa fa-check" />
            {{ t("labels.hardpoint.moduleFitted") }}
          </Pill>
          <span v-if="cargo(mod)" class="module-option__cargo">
            {{ t("labels.hardpoint.moduleCargo", { cargo: cargo(mod) }) }}
          </span>
          <Pill v-if="upcoming(mod)" :variant="PillVariantsEnum.WARNING">
            {{ t(`labels.model.productionStatus.${mod.productionStatus}`) }}
          </Pill>
        </span>
      </button>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
