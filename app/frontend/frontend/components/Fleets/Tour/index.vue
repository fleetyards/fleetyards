<script lang="ts">
export default {
  name: "FleetTour",
};
</script>

<script lang="ts" setup>
import Tour from "@/shared/components/Tour/index.vue";
import type { TourStep } from "@/shared/components/Tour/types";
import { useI18n } from "@/shared/composables/useI18n";

const open = defineModel<boolean>("open", { default: false });

const emit = defineEmits<{
  start: [];
}>();

const { t } = useI18n();

const step = (
  id: string,
  options: Omit<TourStep, "id" | "title" | "text"> = {},
): TourStep => ({
  id,
  title: t(`texts.fleetTour.${id}.title`),
  text: t(`texts.fleetTour.${id}.text`),
  ...options,
});

const SETTINGS = '[data-tour="fleet-settings"]';

// The tabs sit in the side navigation, so the card goes beside them; a narrow
// screen moves it above the bottom bar instead.
const tab = (id: string, target: string, requiresTarget = false) =>
  step(id, { target, placement: "right", requiresTarget });

// Only the flag-gated tabs require their target. The others are always there
// for a manager, but the mobile bar leaves out squadrons and settings, and the
// card is still worth reading centred.
const steps = computed<TourStep[]>(() => [
  step("welcome"),
  tab("members", '[data-tour="fleet-members"]'),
  // At the settings rather than the squadrons tab: roles and the squadrons
  // switch both live there.
  tab("roles", SETTINGS),
  tab("ships", '[data-tour="fleet-ships"]'),
  tab("events", '[data-tour="fleet-events"]', true),
  tab("contracts", '[data-tour="fleet-contracts"]', true),
  tab("rsi", SETTINGS),
  tab("discord", SETTINGS),
  tab("settings", SETTINGS),
]);
</script>

<template>
  <Tour
    v-model:open="open"
    :steps="steps"
    return-focus-fallback='[data-tour="fleet-guide"]'
    @start="emit('start')"
  />
</template>
