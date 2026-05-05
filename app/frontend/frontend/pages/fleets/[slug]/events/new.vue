<script lang="ts">
export default {
  name: "FleetEventNewPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import EventForm from "@/frontend/components/Fleets/Events/EventForm/index.vue";
import {
  type Fleet,
  type FleetMember,
  type Mission,
  useFleetMission,
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
const missionSlugQuery = computed(
  () => (route.query.mission as string | undefined) ?? null,
);

const { data: prefillMission } = useFleetMission(
  fleetSlug,
  computed(() => missionSlugQuery.value || ""),
  {
    query: {
      enabled: computed(() => !!missionSlugQuery.value),
    },
  },
);

const cancel = () => {
  void router.push({
    name: "fleet-events",
    params: { slug: props.fleet.slug },
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
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ t("headlines.fleets.events.create") }}
  </Heading>

  <EventForm
    :fleet="fleet"
    :mission="prefillMission as Mission | undefined"
    @cancel="cancel"
  />
</template>
