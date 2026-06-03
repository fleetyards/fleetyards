<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type Component } from "@/services/fyAdminApi";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { routes as editRoutes } from "./edit/routes";

type Props = {
  component: Component;
};

const props = defineProps<Props>();

const { t } = useI18n();

const crumbs = [
  {
    to: { name: "admin-components", hash: `#${props.component.id}` },
    label: t("nav.admin.components.index"),
  },
  {
    to: { name: "admin-component-edit", params: { id: props.component.id } },
    label: props.component.name,
  },
];
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" :current-id="component.id" />
  <TabNavView :routes="editRoutes" authenticated>
    <template #content>
      <router-view :component="component" />
    </template>
  </TabNavView>
</template>
