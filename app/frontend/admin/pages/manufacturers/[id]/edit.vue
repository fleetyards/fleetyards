<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type Manufacturer } from "@/services/fyAdminApi";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { type TabNavLink } from "@/shared/components/TabNavView/types";
import { useSessionStore } from "@/admin/stores/session";
import { routes as editRoutes } from "./edit/routes";

type Props = {
  manufacturer: Manufacturer;
};

const props = defineProps<Props>();

const { t } = useI18n();

const sessionStore = useSessionStore();

const crumbs = [
  {
    to: { name: "admin-manufacturers", hash: `#${props.manufacturer.id}` },
    label: t("nav.admin.manufacturers.index"),
  },
  {
    to: {
      name: "admin-manufacturer-edit",
      params: { id: props.manufacturer.id },
    },
    label: props.manufacturer.name,
  },
];

// What this company makes, in the lists that already hold it. A tab of its own
// would be a second models list to keep in step with the first, and the filter
// the list already has says the same thing.
const links = computed<TabNavLink[]>(() =>
  [
    {
      access: "models",
      label: t("nav.admin.manufacturers.edit.models"),
      to: {
        name: "admin-models",
        query: { manufacturerIn: [props.manufacturer.slug] },
      },
    },
    {
      access: "components",
      label: t("nav.admin.manufacturers.edit.components"),
      to: {
        name: "admin-components",
        query: { manufacturerIdIn: [props.manufacturer.id] },
      },
    },
    {
      access: "equipment",
      label: t("nav.admin.manufacturers.edit.equipment"),
      to: {
        name: "admin-equipment",
        query: { manufacturerIdIn: [props.manufacturer.id] },
      },
    },
    {
      access: "model_modules",
      label: t("nav.admin.manufacturers.edit.modules"),
      to: {
        name: "admin-model-modules",
        query: { manufacturerIdIn: [props.manufacturer.id] },
      },
    },
  ].filter(({ access }) => sessionStore.hasAccessTo(access)),
);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" :current-id="manufacturer.id" />
  <TabNavView :routes="editRoutes" :links="links" authenticated>
    <template #content>
      <router-view :manufacturer="manufacturer" />
    </template>
  </TabNavView>
</template>
