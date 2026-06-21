<script lang="ts">
export default {
  name: "FleetEventEditLayout",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewItems from "@/shared/components/TabNavView/Items/index.vue";
import { routes as editRoutes } from "@/frontend/pages/fleets/[slug]/events/[event]/edit/routes";
import { type Fleet, type FleetMember, useFleetEvent } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();
const comlink = useComlink();

const fleetSlug = computed(() => props.fleet.slug);
const eventSlug = computed(() => route.params.event as string);

const { data: event, refetch } = useFleetEvent(fleetSlug, eventSlug);

onMounted(() => {
  comlink.on("fleet-event-updated", () => void refetch());
  comlink.on("fleet-event-children-changed", () => void refetch());
});

const crumbs = computed(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-events", params: { slug: props.fleet.slug } },
    label: t("headlines.fleets.events.index"),
  },
  ...(event.value
    ? [
        {
          to: {
            name: "fleet-event",
            params: { slug: props.fleet.slug, event: event.value.slug },
          },
          label: event.value.title,
        },
      ]
    : []),
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <TabNavView v-if="event">
    <template #nav>
      <TabNavViewItems
        :routes="editRoutes"
        :authenticated="true"
        :resource-access="resourceAccess"
      />
    </template>
    <template #content>
      <router-view :fleet="fleet" :event="event" />
    </template>
  </TabNavView>
</template>
