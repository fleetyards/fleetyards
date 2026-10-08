<script lang="ts">
export default {
  name: "FleetTour",
};
</script>

<script lang="ts" setup>
import Tour from "@/shared/components/Tour/index.vue";
import type { TourStep } from "@/shared/components/Tour/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useFleetStore } from "@/frontend/stores/fleet";
import { useSessionStore } from "@/frontend/stores/session";

const { t } = useI18n();

const route = useRoute();

const fleetStore = useFleetStore();

const sessionStore = useSessionStore();

const slug = computed(() => fleetStore.tourFleet?.slug ?? "");

const open = computed({
  get: () => fleetStore.tourOpen,
  set: (value) => {
    if (!value) fleetStore.closeTour();
  },
});

// Its own navigation stays inside the fleet; leaving it -- the back button, a
// link in the header -- ends the tour rather than dragging it along.
watch(
  () => route.params.slug,
  (current) => {
    if (open.value && current !== slug.value) fleetStore.closeTour();
  },
);

// Done once it has been shown, not once it ends: leaving mid-tour ends
// nothing, and should not bring it back on every later visit.
const onStart = () => {
  const userId = sessionStore.currentUser?.id;
  const fleetId = fleetStore.tourFleet?.id;

  if (userId && fleetId) fleetStore.clearTour(userId, fleetId);
};

const step = (
  id: string,
  routeName: string,
  options: Omit<TourStep, "id" | "title" | "text" | "route"> = {},
): TourStep => ({
  id,
  title: t(`texts.fleetTour.${id}.title`),
  text: t(`texts.fleetTour.${id}.text`),
  route: { name: routeName, params: { slug: slug.value } },
  ...options,
});

// Events and contracts are flag-gated, so they are shown on the overview as
// tabs -- present only while switched on -- rather than as pages to open.
// Every other step goes to the page where the setting lives; a control that is
// not there (no Discord install link yet) leaves its card centred.
const steps = computed<TourStep[]>(() => [
  step("welcome", "fleet"),
  step("events", "fleet", {
    target: '[data-tour="fleet-events"]',
    placement: "right",
    requiresTarget: true,
  }),
  step("contracts", "fleet", {
    target: '[data-tour="fleet-contracts"]',
    placement: "right",
    requiresTarget: true,
  }),
  step("members", "fleet-members", { target: '[data-tour="fleet-invite"]' }),
  step("ships", "fleet-ships", { target: '[data-tour="fleet-fleetchart"]' }),
  step("membership", "fleet-settings-membership", {
    target: '[data-tour="fleet-ships-filter"]',
  }),
  step("rsi", "fleet-settings-rsi", { target: '[data-tour="fleet-rsi"]' }),
  step("roles", "fleet-settings-roles", {
    target: '[data-tour="fleet-roles"]',
  }),
  step("squadrons", "fleet-settings-squadrons", {
    target: '[data-tour="fleet-squadrons-switch"]',
  }),
  step("discord", "fleet-settings-discord", {
    target: '[data-tour="fleet-discord"]',
  }),
  step("settings", "fleet-settings-fleet", {
    target: '[data-tour="fleet-public"]',
  }),
]);
</script>

<template>
  <Tour
    v-model:open="open"
    :steps="steps"
    return-focus-fallback='[data-tour="fleet-guide"]'
    @start="onStart"
  />
</template>
