<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type Equipment } from "@/services/fyAdminApi";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { routes as editRoutes } from "./edit/routes";

type Props = {
  equipment: Equipment;
};

const props = defineProps<Props>();

const { t } = useI18n();

const crumbs = [
  {
    to: { name: "admin-equipment", hash: `#${props.equipment.id}` },
    label: t("nav.admin.equipment.index"),
  },
  {
    to: { name: "admin-equipment-edit", params: { id: props.equipment.id } },
    label: props.equipment.name,
  },
];
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" :current-id="equipment.id" />
  <TabNavView :routes="editRoutes" authenticated>
    <template #content>
      <router-view :equipment="equipment" />
    </template>
  </TabNavView>
</template>
