<script lang="ts">
export default {
  name: "FleetSquadronNewPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import SquadronDetailsForm from "@/frontend/components/Fleets/Squadrons/SquadronDetailsForm/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Fleet, type FleetMember } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

/*
 * Only the written half. A squadron's pictures are attachments on a record, so
 * there is nothing to attach them to until it exists -- saving here hands the
 * author straight to the images tab of the editor.
 */
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

  <SquadronDetailsForm :fleet="props.fleet" />
</template>
