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
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { type TabNavLink } from "@/shared/components/TabNavView/types";
import { squadronDetailRoutes } from "@/frontend/pages/fleets/[slug]/squadrons/routes";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import { useSessionStore } from "@/frontend/stores/session";
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
const sessionStore = useSessionStore();

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

const tabLinks = computed<TabNavLink[]>(() => [
  {
    to: {
      name: "fleet-ships",
      params: { slug: props.fleet.slug },
      query: { squadronSlugIn: [squadronSlug.value] },
    },
    label: t("actions.fleet.squadrons.viewShips"),
  },
  {
    to: {
      name: "fleet-stats",
      params: { slug: props.fleet.slug },
      query: { squadronSlugIn: [squadronSlug.value] },
    },
    label: t("actions.fleet.squadrons.viewStats"),
  },
]);

const openMemberPicker = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SquadronMemberPicker/index.vue"),
    props: { fleet: props.fleet, squadron: squadron.value },
  });
};

const destroyMutation = useDestroyFleetSquadron();

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

const squadronUpdatedComlink = ref<() => void>();
const squadronMembersComlink = ref<() => void>();

onMounted(() => {
  squadronUpdatedComlink.value = comlink.on(
    "fleet-squadron-updated",
    () => void refetchSquadron(),
  );
  squadronMembersComlink.value = comlink.on(
    "fleet-squadron-members-updated",
    () => void refetchSquadron(),
  );
});

onUnmounted(() => {
  squadronUpdatedComlink.value?.();
  squadronMembersComlink.value?.();
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

    <TabNavView
      :routes="squadronDetailRoutes"
      :links="tabLinks"
      :authenticated="sessionStore.isAuthenticated"
      :resource-access="props.membership?.fleetRole?.resourceAccess"
    >
      <template #content>
        <router-view
          :fleet="props.fleet"
          :membership="props.membership"
          :squadron="squadron"
        />
      </template>
    </TabNavView>
  </template>
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

.squadron-kind {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-left: 12px;
  padding-left: 12px;
  border-left: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
}
</style>
