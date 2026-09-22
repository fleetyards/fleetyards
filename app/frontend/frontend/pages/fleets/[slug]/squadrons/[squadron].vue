<script lang="ts">
export default {
  name: "FleetSquadronPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import MembersList from "@/frontend/components/Fleets/MembersList/index.vue";
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import {
  type Fleet,
  type FleetMember,
  useFleetSquadron,
  useFleetSquadronMembers,
  useDestroyFleetSquadron,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const route = useRoute();
const router = useRouter();

const fleetSlug = computed(() => props.fleet.slug);
const squadronSlug = computed(() => route.params.squadron as string);

const canUpdate = computed(
  () => props.membership?.capabilities?.updateSquadrons ?? false,
);

const canDestroy = computed(
  () => props.membership?.capabilities?.destroySquadrons ?? false,
);

const canManageMembers = computed(
  () => props.membership?.capabilities?.manageSquadronMembers ?? false,
);

const {
  data: squadron,
  isLoading,
  refetch: refetchSquadron,
} = useFleetSquadron(fleetSlug, squadronSlug);

const { data: members, refetch: refetchMembers } = useFleetSquadronMembers(
  fleetSlug,
  squadronSlug,
  {},
);

const memberItems = computed(() => members.value?.items ?? []);

/*
 * The squadron's ships and its numbers are the fleet's own pages, narrowed.
 * Building a second ship list and a second stats page here would be two more
 * implementations of what those pages already do, and they would drift; a
 * squadron is a way of slicing the fleet, so the slice belongs on the page that
 * owns the list.
 */
const filtered = (name: string) => ({
  name,
  params: { slug: props.fleet.slug },
  query: { squadronSlugIn: [squadronSlug.value] },
});

const refetchAll = async () => {
  await Promise.all([refetchSquadron(), refetchMembers()]);
};

const openEditModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SquadronModal/index.vue"),
    props: { fleet: props.fleet, squadron: squadron.value },
  });
};

const openMemberPicker = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SquadronMemberPicker/index.vue"),
    props: { fleet: props.fleet, squadron: squadron.value },
  });
};

const destroyMutation = useDestroyFleetSquadron();

// Disbanding takes nobody out of the fleet, but the squadron itself does not
// come back -- hence danger rather than warning.
const onDestroy = () => {
  displayConfirm({
    text: t("messages.fleet.squadrons.destroy.confirm", {
      name: squadron.value?.name,
    }),
    confirmText: t("actions.delete"),
    tone: AppConfirmTonesEnum.DANGER,
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync({
          fleetSlug: props.fleet.slug,
          slug: squadronSlug.value,
        })
        .then(() => {
          displaySuccess({
            text: t("messages.fleet.squadrons.destroy.success"),
          });
          void router.push({
            name: "fleet-squadrons",
            params: { slug: props.fleet.slug },
          });
        })
        .catch(() => {
          displayAlert({
            text: t("messages.fleet.squadrons.destroy.failure"),
          });
        });
    },
  });
};

const squadronUpdatedComlink = ref();
const squadronMembersComlink = ref();

onMounted(() => {
  squadronUpdatedComlink.value = comlink.on(
    "fleet-squadron-updated",
    () => void refetchAll(),
  );
  squadronMembersComlink.value = comlink.on(
    "fleet-squadron-members-updated",
    () => void refetchAll(),
  );
});

onUnmounted(() => {
  squadronUpdatedComlink.value();
  squadronMembersComlink.value();
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
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Loader :loading="isLoading" />

  <template v-if="squadron">
    <div class="squadron-identity">
      <SquadronEmblem :squadron="squadron" :size="96" />
      <div class="squadron-identity-text">
        <Heading hero size="hero">
          {{ squadron.name }}
          <template #subHeading>
            {{
              t("labels.fleet.squadrons.memberCount", {
                count: squadron.memberCount,
              })
            }}
          </template>
        </Heading>
        <p v-if="squadron.description" class="squadron-description text-muted">
          {{ squadron.description }}
        </p>
      </div>
    </div>

    <Teleport to="#header-right">
      <Btn
        v-if="canManageMembers"
        :size="BtnSizesEnum.MD"
        mobile-icon-only
        data-test="squadron-add-member"
        @click="openMemberPicker"
      >
        <i class="fa-duotone fa-user-plus" />
        {{ t("actions.fleet.squadrons.addMember") }}
      </Btn>
      <Btn
        v-if="canUpdate"
        :size="BtnSizesEnum.MD"
        mobile-icon-only
        data-test="squadron-edit"
        @click="openEditModal"
      >
        <i class="fa-duotone fa-pen" />
        {{ t("actions.edit") }}
      </Btn>
      <Btn
        v-if="canDestroy"
        :size="BtnSizesEnum.MD"
        mobile-icon-only
        data-test="squadron-destroy"
        @click="onDestroy"
      >
        <i class="fa-duotone fa-trash" />
        {{ t("actions.delete") }}
      </Btn>
    </Teleport>

    <!-- Out to the fleet's own pages, narrowed to this squadron, rather than a
         second ship list and a second stats page living here. -->
    <div class="squadron-links">
      <Btn :to="filtered('fleet-ships')" data-test="squadron-ships-link">
        <i class="fa-duotone fa-starship" />
        {{ t("actions.fleet.squadrons.viewShips") }}
      </Btn>
      <Btn :to="filtered('fleet-stats')" data-test="squadron-stats-link">
        <i class="fa-duotone fa-chart-bar" />
        {{ t("actions.fleet.squadrons.viewStats") }}
      </Btn>
    </div>

    <Heading :level="HeadingLevelEnum.H3">
      {{ t("labels.fleet.squadrons.members") }}
    </Heading>

    <MembersList
      :members="memberItems"
      :capabilities="props.membership?.capabilities"
      :empty-visible="!memberItems.length"
      :show-squadrons="false"
    />
  </template>

  <Empty v-else-if="!isLoading" :name="t('labels.fleet.squadrons.index')" />
</template>

<style lang="scss" scoped>
.squadron-identity {
  display: flex;
  align-items: flex-start;
  gap: 20px;
  margin-bottom: 20px;
}

.squadron-identity-text {
  min-width: 0;
}

.squadron-description {
  margin: 8px 0 0;
  max-width: 70ch;
  // Written in a textarea; the paragraphs somebody typed are kept.
  white-space: pre-line;
}

.squadron-links {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 20px;
}
</style>
