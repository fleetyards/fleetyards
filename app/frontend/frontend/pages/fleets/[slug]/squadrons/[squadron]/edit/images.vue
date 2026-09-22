<script lang="ts">
export default {
  name: "FleetSquadronEditImagesPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import SquadronImagesForm from "@/frontend/components/Fleets/Squadrons/SquadronImagesForm/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Fleet, type FleetSquadron } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  squadron: FleetSquadron;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <Heading hero>{{ t("headlines.fleets.squadrons.editImages") }}</Heading>

  <SquadronImagesForm :fleet="fleet" :squadron="squadron" />
</template>
