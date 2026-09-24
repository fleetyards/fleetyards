<script lang="ts">
export default {
  name: "FleetSquadronNewLayout",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import SquadronFormShell from "@/frontend/components/Fleets/Squadrons/SquadronFormShell/index.vue";
import { squadronFormRoutes } from "@/frontend/pages/fleets/[slug]/squadrons/form/routes";
import { useI18n } from "@/shared/composables/useI18n";
import { type Fleet, type FleetMember } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const resourceAccess = computed(
  () => props.membership?.fleetRole?.resourceAccess,
);

const tabRoutes = squadronFormRoutes("create", [
  "fleet:squadrons:create",
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
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading hero size="hero">
    {{ t("headlines.fleets.squadrons.create") }}
  </Heading>

  <SquadronFormShell
    :fleet="props.fleet"
    :tab-routes="tabRoutes"
    :resource-access="resourceAccess"
  />
</template>
