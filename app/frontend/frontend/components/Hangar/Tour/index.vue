<script lang="ts">
export default {
  name: "HangarTour",
};
</script>

<script lang="ts" setup>
import Tour from "@/shared/components/Tour/index.vue";
import type { TourStep } from "@/shared/components/Tour/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useSessionStore } from "@/frontend/stores/session";

const open = defineModel<boolean>("open", { default: false });

const { t } = useI18n();

const hangarStore = useHangarStore();

const sessionStore = useSessionStore();

const step = (
  id: string,
  options: Omit<TourStep, "id" | "title" | "text"> = {},
): TourStep => ({
  id,
  title: t(`texts.hangarTour.${id}.title`),
  text: t(`texts.hangarTour.${id}.text`),
  ...options,
});

const steps = computed<TourStep[]>(() => [
  step("welcome"),
  step("add", { target: '[data-tour="hangar-add"]', placement: "top" }),
  step("sync", { target: '[data-tour="hangar-sync"]', requiresTarget: true }),
  step("display", {
    target: '[data-tour="hangar-display"]',
    requiresTarget: true,
  }),
  step("groups", {
    target: '[data-tour="hangar-groups"]',
    requiresTarget: true,
  }),
  step("vehicle", {
    target: '[data-tour="vehicle-menu"]',
    placement: "left",
    requiresTarget: true,
  }),
  step("wishlist", {
    target: '[data-tour="hangar-wishlist"]',
    requiresTarget: true,
  }),
  step("fleetchart", {
    target: '[data-tour="hangar-fleetchart"]',
    requiresTarget: true,
  }),
  step("stats", {
    target: '[data-tour="hangar-stats"]',
    requiresTarget: true,
  }),
  step("share", {
    target: '[data-tour="hangar-share"]',
    requiresTarget: true,
  }),
  step("menu", {
    target: '[data-tour="hangar-menu"]',
    placement: "left",
    requiresTarget: true,
  }),
]);

const onEnd = () => {
  const userId = sessionStore.currentUser?.id;

  if (userId) hangarStore.markTourSeen(userId);
};
</script>

<template>
  <Tour
    v-model:open="open"
    :steps="steps"
    return-focus-fallback='[data-tour="hangar-menu"] button'
    @end="onEnd"
  />
</template>
