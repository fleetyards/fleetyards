<script lang="ts">
export default {
  name: "FleetSquadronEditLayout",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewItems from "@/shared/components/TabNavView/Items/index.vue";
import { routes as editRoutes } from "@/frontend/pages/fleets/[slug]/squadrons/[squadron]/edit/routes";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
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
const comlink = useComlink();

const fleetSlug = computed(() => props.fleet.slug);
const squadronSlug = computed(() => route.params.squadron as string);

const { data: squadron, refetch } = useFleetSquadron(fleetSlug, squadronSlug);

const resourceAccess = computed(
  () => props.membership?.fleetRole?.resourceAccess,
);

// The images tab saves attachments; the card the details tab drew has to pick
// them up without a reload.
const squadronUpdatedComlink = ref<() => void>();

onMounted(() => {
  squadronUpdatedComlink.value = comlink.on(
    "fleet-squadron-updated",
    () => void refetch(),
  );
});

onUnmounted(() => {
  squadronUpdatedComlink.value?.();
});

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

  <TabNavView v-if="squadron">
    <template #nav>
      <TabNavViewItems
        :routes="editRoutes"
        :authenticated="true"
        :resource-access="resourceAccess"
      />
    </template>
    <template #content>
      <router-view :fleet="fleet" :squadron="squadron" />
    </template>
  </TabNavView>
</template>
