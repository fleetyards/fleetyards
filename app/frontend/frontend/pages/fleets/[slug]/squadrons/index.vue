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
  useMoveFleetSquadron,
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

const moveMutation = useMoveFleetSquadron();

/*
 * A drag moves one squadron, so the one that moved is where the two orders
 * first and last differ: it sits at one end of that window in the old order
 * and at the other end in the new.
 */
const movedId = (before: string[], after: string[]) => {
  const first = before.findIndex((id, index) => id !== after[index]);
  const last = before.findLastIndex((id, index) => id !== after[index]);

  return before[first] === after[last] ? before[first] : after[first];
};

/*
 * Each row is dragged on its own, but the order is one sequence across the
 * fleet with squadrons and teams interleaved in it. So the move is placed
 * against its new neighbour in that sequence -- after the squadron now ahead
 * of it in the row, or before the one behind it -- and the server is told that
 * place. Counting it within the row alone would put it among the other row.
 */
const onSort = (rowIds: string[]) => {
  const previous = orderedSquadrons.value;
  const isTeamRow =
    previous.find((squadron) => squadron.id === rowIds[0])?.team ?? false;
  const previousRow = previous
    .filter((squadron) => (squadron.team ?? false) === isTeamRow)
    .map((squadron) => squadron.id);

  const id = movedId(previousRow, rowIds);
  const moved = previous.find((squadron) => squadron.id === id);

  if (!moved) return;

  const others = previous.filter((squadron) => squadron.id !== id);
  const rowIndex = rowIds.indexOf(id);
  const ahead = rowIds[rowIndex - 1];
  const behind = rowIds[rowIndex + 1];
  const position = ahead
    ? others.findIndex((squadron) => squadron.id === ahead) + 1
    : others.findIndex((squadron) => squadron.id === behind);

  orderedSquadrons.value = [
    ...others.slice(0, position),
    moved,
    ...others.slice(position),
  ];

  void moveMutation
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: moved.slug,
      data: { position },
    })
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
