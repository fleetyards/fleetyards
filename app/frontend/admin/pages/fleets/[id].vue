<script lang="ts" setup>
import { useFleet as useFleetQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewItems from "@/shared/components/TabNavView/Items/index.vue";
import { routes as fleetChildRoutes } from "./[id]/routes";
import { useI18n } from "@/shared/composables/useI18n";

const route = useRoute();
const { t } = useI18n();

const { data: fleet, ...asyncStatus } = useFleetQuery(
  route.params.id as string,
);

const crumbs = computed(() => [
  {
    to: { name: "admin-fleets", hash: fleet.value ? `#${fleet.value.id}` : "" },
    label: t("nav.admin.fleets.index"),
  },
  {
    to: {
      name: "admin-fleet-edit",
      params: { id: route.params.id },
    },
    label: fleet.value?.name || "",
  },
]);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <BreadCrumbs :crumbs="crumbs" />

      <TabNavView>
        <template #nav>
          <TabNavViewItems :routes="fleetChildRoutes" :authenticated="true" />
        </template>
        <template #content>
          <router-view :fleet="fleet" />
        </template>
      </TabNavView>
    </template>
  </AsyncData>
</template>
