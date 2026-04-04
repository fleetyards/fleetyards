<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelExtended } from "@/services/fyAdminApi";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewItems from "@/shared/components/TabNavView/Items/index.vue";
import { routes as editRoutes } from "./edit/routes";
import { useModelsStore } from "@/admin/stores/models";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

const crumbs = [
  {
    to: { name: "admin-models", hash: `#${props.model.id}` },
    label: t("nav.admin.models.index"),
  },
  {
    to: { name: "admin-model-edit", params: { id: props.model.id } },
    label: props.model.name,
  },
];

const modelsStore = useModelsStore();
</script>

<template>
  <BreadCrumbs
    :crumbs="crumbs"
    :stepper-list="modelsStore.list"
    :stepper-list-meta="modelsStore.listMeta"
    :current-id="model.id"
  />
  <TabNavView>
    <template #nav>
      <TabNavViewItems :routes="editRoutes" :authenticated="true" />
    </template>
    <template #content>
      <router-view :model="model" />
    </template>
  </TabNavView>
</template>
