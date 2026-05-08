<script lang="ts">
export default {
  name: "FleetMissionNewPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import MissionForm from "@/frontend/components/Fleets/Missions/MissionForm/index.vue";
import { type Fleet, type FleetMember } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();

const cancel = () => {
  void router.push({
    name: "fleet-missions",
    params: { slug: props.fleet.slug },
  });
};

const crumbs = computed(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-missions", params: { slug: props.fleet.slug } },
    label: t("nav.fleets.missions.index"),
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ t("headlines.fleets.missions.create") }}
  </Heading>

  <MissionForm :fleet="fleet" @cancel="cancel" />
</template>
