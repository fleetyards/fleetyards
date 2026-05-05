<script lang="ts">
export default {
  name: "FleetEventEditPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import EventForm from "@/frontend/components/Fleets/Events/EventForm/index.vue";
import {
  type Fleet,
  type FleetMember,
  useFleetEvent,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const fleetSlug = computed(() => props.fleet.slug);
const eventSlug = computed(() => route.params.event as string);

const { data: event } = useFleetEvent(fleetSlug, eventSlug);

const cancel = () => {
  if (!event.value) {
    void router.push({
      name: "fleet-events",
      params: { slug: props.fleet.slug },
    });
    return;
  }
  void router.push({
    name: "fleet-event",
    params: { slug: props.fleet.slug, event: event.value.slug },
  });
};

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

  <Heading size="hero" hero>
    {{ t("headlines.fleets.events.edit") }}
  </Heading>

  <EventForm v-if="event" :fleet="fleet" :event="event" @cancel="cancel" />
</template>
