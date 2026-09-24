<script lang="ts">
export default {
  name: "FleetSquadronsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Grid from "@/shared/components/base/Grid/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import SquadronPanel from "@/frontend/components/Fleets/Squadrons/SquadronPanel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type Fleet,
  type FleetMember,
  type FleetSquadron,
  useFleetSquadrons,
  useSortFleetSquadrons,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const fleetSlug = computed(() => props.fleet.slug);

const canCreate = computed(
  () => props.membership?.capabilities?.createSquadrons ?? false,
);

const {
  data: squadrons,
  isLoading,
  refetch,
} = useFleetSquadrons(fleetSlug, { perPage: "all" });

const canSort = computed(
  () => props.membership?.capabilities?.updateSquadrons ?? false,
);

/*
 * The order is the fleet's own, so the list has to hold it locally while the
 * write is in flight: re-reading the server between the drop and the response
 * would snap the card back to where it was dragged from.
 */
const orderedSquadrons = ref<FleetSquadron[]>([]);

watch(
  () => squadrons.value?.items,
  (items) => {
    orderedSquadrons.value = [...(items ?? [])];
  },
  { immediate: true },
);

/*
 * Two rows, because they are two things: a member belongs to one squadron, and
 * can be on any number of teams. Shown together they read as one list with an
 * invisible rule running through half of it.
 */
const squadronList = computed(() =>
  orderedSquadrons.value.filter((squadron) => !squadron.team),
);

const teamList = computed(() =>
  orderedSquadrons.value.filter((squadron) => squadron.team),
);

const sortMutation = useSortFleetSquadrons();

/*
 * Each row is dragged on its own, but the position is one sequence across the
 * fleet -- so what goes to the server is both rows, in the order they are now
 * drawn in. Sending only the dragged row would renumber it from the front and
 * interleave it with the other.
 */
const onSort = (rowIds: string[]) => {
  const previous = orderedSquadrons.value;
  const held = (id: string) => previous.find((squadron) => squadron.id === id);
  const row = rowIds.map(held).filter(Boolean) as FleetSquadron[];
  const isTeamRow = row[0]?.team ?? false;

  const kept = previous.filter(
    (squadron) => (squadron.team ?? false) !== isTeamRow,
  );

  orderedSquadrons.value = isTeamRow ? [...kept, ...row] : [...row, ...kept];

  const ids = orderedSquadrons.value.map((squadron) => squadron.id);

  void sortMutation
    .mutateAsync({ fleetSlug: props.fleet.slug, data: { sorting: ids } })
    .then(() => {
      comlink.emit("fleet-squadron-updated");
    })
    .catch(() => {
      orderedSquadrons.value = previous;

      displayAlert({ text: t("messages.fleet.squadrons.sort.failure") });
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
      :to="{ name: 'fleet-squadron-new', params: { slug: fleet.slug } }"
    >
      <i class="fa-light fa-plus" />
      {{ t("actions.fleet.squadrons.create") }}
    </Btn>
  </Teleport>

  <Loader :loading="isLoading" />

  <Grid
    v-if="squadronList.length"
    :records="squadronList"
    primary-key="id"
    :sortable="canSort"
    sort-handle=".squadron-panel-grip"
    @sort="onSort"
  >
    <template #default="{ record }">
      <SquadronPanel
        :squadron="record"
        :sortable="canSort"
        :to="{
          name: 'fleet-squadron',
          params: { slug: fleet.slug, squadron: record.slug },
        }"
      />
    </template>
  </Grid>

  <!-- Headed, unlike the row above it: the page is called Squadrons, so the
       first row needs no label and the second one does. -->
  <template v-if="teamList.length">
    <Heading :level="HeadingLevelEnum.H2" mt>
      {{ t("headlines.fleets.squadrons.teams") }}
    </Heading>

    <Grid
      :records="teamList"
      primary-key="id"
      :sortable="canSort"
      sort-handle=".squadron-panel-grip"
      @sort="onSort"
    >
      <template #default="{ record }">
        <SquadronPanel
          :squadron="record"
          :sortable="canSort"
          :to="{
            name: 'fleet-squadron',
            params: { slug: fleet.slug, squadron: record.slug },
          }"
        />
      </template>
    </Grid>
  </template>

  <Empty
    v-else-if="!isLoading && !squadronList.length"
    :name="t('labels.fleet.squadrons.index')"
    data-test="squadrons-empty"
  />
</template>
