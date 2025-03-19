<script lang="ts">
export default {
  name: "FleetSettingsRouterView",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewItems from "@/shared/components/TabNavView/Items/index.vue";
import { routes as fleetRoutes } from "./settings/routes";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  useLeaveFleet as useLeaveFleetMutation,
  type ValidationError,
} from "@/services/fyApi";
import { type ErrorType } from "@/services/fyApi/axiosClient";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";

const { t } = useI18n();

const { displayAlert, displaySuccess, displayConfirm } = useAppNotifications();

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const route = useRoute();

const crumbs = computed(() => {
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
  if (props.fleet.myFleet && props.fleet.myRole === "admin") {
    return t("texts.fleets.leaveInfo");
  }

  return null;
});

const canEdit = computed(() => {
  return props.fleet?.myRole === "admin";
});

const comlink = useComlink();

const router = useRouter();

const mutation = useLeaveFleetMutation();

const leave = () => {
  if (!canEdit.value || leaving.value) return;

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

          // eslint-disable-next-line @typescript-eslint/no-empty-function
          await router.push({ name: "home" }).catch(() => {});
        })
        .catch((error) => {
          const response = error as unknown as ErrorType<ValidationError>;

          if (response.message) {
            displayAlert({
              text: response.message,
            });
          } else {
            displayAlert({
              text: t("messages.fleet.leave.failure"),
            });
          }
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

const hasAccess = (access: string) => {
  if (!access || access === "all") {
    return true;
  }

  return canEdit.value;
};
</script>

<template>
  <TabNavView :routes="fleetRoutes">
    <template #nav>
      <TabNavViewItems
        :routes="fleetRoutes"
        :authenticated="sessionStore.isAuthenticated"
        :has-access-to="hasAccess"
      />

      <li
        v-if="fleet"
        v-tooltip="leaveTooltip"
        :class="{
          disabled: canEdit || leaving,
        }"
      >
        <a @click="leave">
          <i class="fal fa-sign-out" />
          {{ t("actions.fleet.leave", { fleet: fleet.name }) }}
        </a>
      </li>
    </template>
    <template #content>
      <BreadCrumbs :crumbs="crumbs" />
      <Heading>{{ t(`headlines.${route.meta.title}`) }}</Heading>
      <router-view :fleet="fleet" />
    </template>
  </TabNavView>
</template>
