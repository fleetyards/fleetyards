<script lang="ts">
export default {
  name: "FleetSquadronPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Loader from "@/shared/components/Loader/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import {
  type Fleet,
  type FleetMember,
  useFleetSquadron,
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
  await refetchSquadron();
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
    <div
      v-if="squadron.header?.mediumUrl"
      class="squadron-header"
      :style="{ backgroundImage: `url(${squadron.header.mediumUrl})` }"
    />

    <div class="squadron-identity">
      <img
        v-if="squadron.logo?.mediumUrl"
        :src="squadron.logo.mediumUrl"
        :alt="squadron.name"
        class="squadron-logo"
      />
      <SquadronEmblem v-else :squadron="squadron" :size="96" />
      <div class="squadron-identity-text">
        <Heading hero size="hero">
          {{ squadron.name }}
          <template #subHeading>
            {{
              t("labels.fleet.squadrons.memberCount", {
                count: squadron.memberCount,
              })
            }}
            <!-- The lists say which of the two rows a card came from; this page
                 is reached from both and would otherwise say neither. -->
            <span
              v-if="squadron.team"
              v-tooltip="t('labels.fleet.squadrons.teamHint')"
              class="squadron-kind"
              data-test="squadron-team"
            >
              <i class="fa-duotone fa-user-group" />
              {{ t("labels.fleet.squadrons.team") }}
            </span>
          </template>
        </Heading>
      </div>
    </div>

    <Teleport to="#header-right">
      <Btn
        v-if="canManageMembers"
        :size="BtnSizesEnum.MD"
        mobile-icon-only
        data-test="squadron-manage-members"
        @click="openMemberPicker"
      >
        <i class="fa-duotone fa-users-gear" />
        {{ t("actions.fleet.squadrons.manageMembers") }}
      </Btn>
      <Btn
        v-if="canUpdate"
        :size="BtnSizesEnum.MD"
        mobile-icon-only
        data-test="squadron-edit"
        :to="{
          name: 'fleet-squadron-edit',
          params: { slug: props.fleet.slug, squadron: squadronSlug },
        }"
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

    <div class="row">
      <div class="col-12 col-md-8">
        <Panel fill-height>
          <PanelBody class="squadron-description-body">
            <p v-if="squadron.description" class="squadron-description">
              {{ squadron.description }}
            </p>
            <Empty
              v-else
              inline
              hide-actions
              :name="t('labels.fleet.squadrons.description')"
            >
              <template #info />
            </Empty>
          </PanelBody>
        </Panel>
      </div>

      <!-- Out to the fleet's own pages, narrowed to this squadron, rather than
           a second roster, a second ship list and a second stats page living
           here. Stacked, so each reads as a destination rather than as one of a
           row of buttons. -->
      <div class="col-12 col-md-4">
        <div class="squadron-links">
          <Btn
            block
            :to="filtered('fleet-members-index')"
            data-test="squadron-members-link"
          >
            <i class="fa-duotone fa-users" />
            {{ t("actions.fleet.squadrons.viewMembers") }}
          </Btn>
          <Btn
            block
            :to="filtered('fleet-ships')"
            data-test="squadron-ships-link"
          >
            <i class="fa-duotone fa-starship" />
            {{ t("actions.fleet.squadrons.viewShips") }}
          </Btn>
          <Btn
            block
            :to="filtered('fleet-stats')"
            data-test="squadron-stats-link"
          >
            <i class="fa-duotone fa-chart-bar" />
            {{ t("actions.fleet.squadrons.viewStats") }}
          </Btn>
        </div>
      </div>
    </div>
  </template>

  <Empty v-else-if="!isLoading" :name="t('labels.fleet.squadrons.index')" />
</template>

<style lang="scss" scoped>
// Its own band rather than a backdrop behind the text: a squadron picks this
// picture, and a heading laid over an arbitrary photograph is unreadable about
// half the time.
.squadron-header {
  height: 220px;
  margin-bottom: 20px;
  border-radius: var(--radius-surface, 16px);
  background-position: center;
  background-size: cover;
  background-repeat: no-repeat;
}

.squadron-identity {
  display: flex;
  align-items: flex-start;
  gap: 20px;
  margin-bottom: 20px;
}

.squadron-logo {
  width: 192px;
  max-width: 40vw;
  height: auto;
  flex-shrink: 0;
  object-fit: contain;
}

.squadron-identity-text {
  min-width: 0;
}

.squadron-kind {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-left: 12px;
  padding-left: 12px;
  border-left: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
}

// PanelBody opens at 4px, which is tuned to sit under a heading that closes at
// 12px. There is no heading on this panel, so the text sat against the top edge
// while the bottom kept its 18px.
.squadron-description-body {
  padding: 18px;
}

.squadron-description {
  margin: 0;
  // Written in a textarea; the paragraphs somebody typed are kept.
  white-space: pre-line;
}

// Centred in the panel, the way an empty list is in its own column.
.squadron-description-body :deep(.empty-list) {
  margin-inline: auto;
  text-align: center;
}

.squadron-links {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
</style>
