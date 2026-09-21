<script lang="ts">
export default {
  name: "FleetSquadronsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Grid from "@/shared/components/base/Grid/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import SquadronCard from "@/frontend/components/Fleets/Squadrons/SquadronCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FleetMember,
  type FleetSquadron,
  useFleetSquadrons,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();

const fleetSlug = computed(() => props.fleet.slug);

const canCreate = computed(
  () => props.membership?.capabilities?.createSquadrons ?? false,
);

const {
  data: squadrons,
  isLoading,
  refetch,
} = useFleetSquadrons(fleetSlug, {});

const squadronList = computed<FleetSquadron[]>(
  () => squadrons.value?.items ?? [],
);

const openSquadronModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SquadronModal/index.vue"),
    props: { fleet: props.fleet },
  });
};

const squadronCreatedComlink = ref();
const squadronUpdatedComlink = ref();

onMounted(() => {
  squadronCreatedComlink.value = comlink.on(
    "fleet-squadron-created",
    () => void refetch(),
  );
  squadronUpdatedComlink.value = comlink.on(
    "fleet-squadron-updated",
    () => void refetch(),
  );
});

onUnmounted(() => {
  squadronCreatedComlink.value();
  squadronUpdatedComlink.value();
});

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading hero size="hero">
    {{ t("headlines.fleets.squadrons.index") }}
  </Heading>

  <Teleport to="#header-right">
    <Btn
      v-if="canCreate"
      :size="BtnSizesEnum.MD"
      mobile-icon-only
      data-test="create-squadron"
      @click="openSquadronModal"
    >
      <i class="fa-light fa-plus" />
      {{ t("actions.fleet.squadrons.create") }}
    </Btn>
  </Teleport>

  <Loader :loading="isLoading" />

  <Grid v-if="squadronList.length" :records="squadronList" primary-key="id">
    <template #default="{ record }">
      <SquadronCard :fleet="props.fleet" :squadron="record" />
    </template>
  </Grid>

  <Empty
    v-else-if="!isLoading"
    :name="t('labels.fleet.squadrons.index')"
    data-test="squadrons-empty"
  />
</template>
