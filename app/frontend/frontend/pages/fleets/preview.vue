<script lang="ts">
export default {
  name: "FleetPreviewPage",
};
</script>

<script lang="ts" setup>
import FeaturePreview from "@/frontend/components/FeaturePreview/index.vue";
import type { FeaturePreviewItem } from "@/frontend/components/FeaturePreview/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useFleetStore } from "@/frontend/stores/fleet";

const { t } = useI18n();

const fleetStore = useFleetStore();

const FEATURES = [
  { id: "members", icon: "fa-duotone fa-users" },
  { id: "ships", icon: "fa-duotone fa-list-ul" },
  { id: "fleetchart", icon: "fa-duotone fa-ruler-combined" },
  { id: "stats", icon: "fa-duotone fa-chart-pie" },
  { id: "allies", icon: "fa-duotone fa-handshake" },
  { id: "discord", icon: "fa-brands fa-discord" },
];

const features = computed<FeaturePreviewItem[]>(() =>
  FEATURES.map((feature) => ({
    ...feature,
    title: t(`texts.fleetPreview.${feature.id}.title`),
    text: t(`texts.fleetPreview.${feature.id}.text`),
  })),
);
</script>

<template>
  <FeaturePreview
    :title="t('headlines.fleets.preview.title')"
    :lead="t('headlines.fleets.preview.lead')"
    :features="features"
    :back-route="{ name: 'fleet-add' }"
    @login="fleetStore.hidePreview()"
  />
</template>
