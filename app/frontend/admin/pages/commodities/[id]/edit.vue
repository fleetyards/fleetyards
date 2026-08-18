<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type Commodity } from "@/services/fyAdminApi";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { routes as editRoutes } from "./edit/routes";

type Props = {
  commodity: Commodity;
};

const props = defineProps<Props>();

const { t } = useI18n();

const crumbs = [
  {
    to: { name: "admin-commodities", hash: `#${props.commodity.id}` },
    label: t("nav.admin.commodities.index"),
  },
  {
    to: { name: "admin-commodity-edit", params: { id: props.commodity.id } },
    label: props.commodity.name,
  },
];
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" :current-id="commodity.id" />
  <TabNavView :routes="editRoutes" authenticated>
    <template #content>
      <router-view :commodity="commodity" />
    </template>
  </TabNavView>
</template>
