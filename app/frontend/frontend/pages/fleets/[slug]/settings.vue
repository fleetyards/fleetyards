<script lang="ts">
export default {
  name: "FleetSettingsRouterView",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewItems from "@/shared/components/TabNavView/Items/index.vue";
import { routes as fleetRoutes } from "./settings/routes";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FeatureFlagName,
  useLeaveFleet as useLeaveFleetMutation,
  type FleetMember,
} from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";

const { t } = useI18n();

const { displayAlert, displaySuccess, displayConfirm } = useAppNotifications();

type Props = {
  fleet: Fleet;
  membership?: FleetMember;
};

const props = defineProps<Props>();

const route = useRoute();

const { isFleetFeatureEnabled } = useFeatures();

/*
 * A tab gated on a feature flag must not be offered while the flag is off: the
 * router's guard answers 404, so the strip would hand out a row that only ever
 * leads to a dead page. `TabNavViewItems` filters on privileges alone -- this
 * is the first settings route to carry a flag -- so the list is narrowed here,
 * where the fleet whose flags decide is already to hand.
 */
const visibleRoutes = computed(() =>
  fleetRoutes.filter((settingsRoute) => {
    const feature = settingsRoute.meta?.feature;
    const fleetSetting = settingsRoute.meta?.fleetSetting;

    if (fleetSetting && !props.fleet[fleetSetting]) return false;

    if (!feature) return true;

    return [feature]
      .flat()
      .every((name) =>
        isFleetFeatureEnabled(props.fleet, name as FeatureFlagName),
      );
  }),
);

const crumbs = computed<Crumb[]>(() => {
  return [
    {
      to: {
        name: "fleet",
        params: {
          slug: props.fleet.slug,
        },
      },
      label: props.fleet.name,
    },
  ];
});

const sessionStore = useSessionStore();

const leaving = ref(false);

const leaveTooltip = computed(() => {
  if (!props.membership?.isDestroyAllowed) {
    return t("texts.fleets.leaveInfo");
  }

  return null;
});

const comlink = useComlink();

const router = useRouter();

const mutation = useLeaveFleetMutation();

const leave = () => {
  if (!props.membership?.isDestroyAllowed || leaving.value) return;

  leaving.value = true;

  displayConfirm({
    text: t("messages.confirm.fleet.leave"),
    onConfirm: async () => {
      await mutation
        .mutateAsync({
          fleetSlug: props.fleet.slug,
        })
        .then(async () => {
          comlink.emit("fleet-update");

          displaySuccess({
            text: t("messages.fleet.leave.success"),
          });

          await router.push({ name: "home" }).catch(() => {});
        })
        .catch((error) => {
          const { message } = validationErrorFrom(error);

          displayAlert({
            text: message || t("messages.fleet.leave.failure"),
          });
        })
        .finally(() => {
          leaving.value = false;
        });
    },
    onClose: () => {
      leaving.value = false;
    },
  });
};
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <TabNavView
    :routes="visibleRoutes"
    :authenticated="sessionStore.isAuthenticated"
    :resource-access="membership?.fleetRole?.resourceAccess"
  >
    <template #nav>
      <TabNavViewItems
        :routes="visibleRoutes"
        :authenticated="sessionStore.isAuthenticated"
        :resource-access="membership?.fleetRole?.resourceAccess"
      />
      <li
        v-if="fleet"
        v-tooltip="leaveTooltip"
        :class="{
          disabled: !membership?.isDestroyAllowed || leaving,
        }"
      >
        <a @click="leave">
          <i class="fa-light fa-sign-out" />
          {{ t("actions.fleet.leave", { fleet: fleet.name }) }}
        </a>
      </li>
    </template>
    <template #content>
      <Heading hero>{{ t(`headlines.${route.meta.title}`) }}</Heading>
      <router-view :fleet="fleet" :membership="membership" />
    </template>
  </TabNavView>
</template>
