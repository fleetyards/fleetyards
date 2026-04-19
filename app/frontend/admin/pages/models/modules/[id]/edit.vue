<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelModule } from "@/services/fyAdminApi";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewItems from "@/shared/components/TabNavView/Items/index.vue";
import { routes as editRoutes } from "./edit/routes";

type Props = {
  modelModule: ModelModule;
};

const props = defineProps<Props>();

const { t } = useI18n();

const crumbs = [
  {
    to: { name: "admin-models" },
    label: t("nav.admin.models.index"),
  },
  {
    to: { name: "admin-model-modules" },
    label: t("headlines.admin.modelModules.index"),
  },
  {
    to: {
      name: "admin-model-module-edit",
      params: { id: props.modelModule.id },
    },
    label: props.modelModule.name,
  },
];
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <TabNavView>
    <template #nav>
      <TabNavViewItems :routes="editRoutes" :authenticated="true" />
    </template>
    <template #content>
      <router-view :model-module="modelModule" />
    </template>
  </TabNavView>
</template>
