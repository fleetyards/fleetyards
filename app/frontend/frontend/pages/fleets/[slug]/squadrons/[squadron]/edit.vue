<script lang="ts">
export default {
  name: "FleetSquadronEditLayout",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import SquadronFormShell from "@/frontend/components/Fleets/Squadrons/SquadronFormShell/index.vue";
import { squadronFormRoutes } from "@/frontend/pages/fleets/[slug]/squadrons/form/routes";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Fleet,
  type FleetMember,
  useFleetSquadron,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();

const fleetSlug = computed(() => props.fleet.slug);
const squadronSlug = computed(() => route.params.squadron as string);

const { data: squadron, isLoading } = useFleetSquadron(fleetSlug, squadronSlug);

const resourceAccess = computed(
  () => props.membership?.fleetRole?.resourceAccess,
);

const tabRoutes = squadronFormRoutes("edit", [
  "fleet:squadrons:update",
  "fleet:squadrons:manage",
  "fleet:manage",
]);

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-squadrons", params: { slug: props.fleet.slug } },
    label: t("headlines.fleets.squadrons.index"),
  },
  ...(squadron.value
    ? [
        {
          to: {
            name: "fleet-squadron",
            params: { slug: props.fleet.slug, squadron: squadron.value.slug },
          },
          label: squadron.value.name,
        },
      ]
    : []),
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Loader :loading="isLoading" />

  <!-- Held until the squadron is here. A form reads its initial values once, so
       building it on a record that has not arrived opens every field empty. -->
  <template v-if="squadron">
    <Heading hero size="hero">
      {{ t("headlines.fleets.squadrons.edit") }}
    </Heading>

    <SquadronFormShell
      :key="squadron.id"
      :fleet="props.fleet"
      :squadron="squadron"
      :tab-routes="tabRoutes"
      :resource-access="resourceAccess"
    />
  </template>
</template>
