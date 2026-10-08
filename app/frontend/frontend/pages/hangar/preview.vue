<script lang="ts">
export default {
  name: "HangarPreviewPage",
};
</script>

<script lang="ts" setup>
import FeaturePreview from "@/frontend/components/FeaturePreview/index.vue";
import type { FeaturePreviewItem } from "@/frontend/components/FeaturePreview/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useHangarStore } from "@/frontend/stores/hangar";

const { t } = useI18n();

const hangarStore = useHangarStore();

const FEATURES = [
  { id: "sync", icon: "fa-duotone fa-rotate" },
  { id: "organise", icon: "fa-duotone fa-object-group" },
  { id: "wishlist", icon: "fa-duotone fa-wand-sparkles" },
  { id: "fleetchart", icon: "fa-duotone fa-ruler-combined" },
  { id: "stats", icon: "fa-duotone fa-chart-pie" },
  { id: "share", icon: "fa-duotone fa-share-nodes" },
];

const features = computed<FeaturePreviewItem[]>(() =>
  FEATURES.map((feature) => ({
    ...feature,
    title: t(`texts.hangarPreview.${feature.id}.title`),
    text: t(`texts.hangarPreview.${feature.id}.text`),
  })),
);
</script>

<template>
  <FeaturePreview
    :title="t('headlines.hangar.preview.title')"
    :lead="t('headlines.hangar.preview.lead')"
    :features="features"
    :back-route="{ name: 'hangar' }"
    @login="hangarStore.hidePreview()"
  />
</template>
