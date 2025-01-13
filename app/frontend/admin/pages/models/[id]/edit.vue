<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelExtended } from "@/services/fyAdminApi";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { routes as editRoutes } from "./edit/routes";
import { RouteRecordName } from "vue-router";

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
];

const route = useRoute();

const activeRoute = (routeName?: RouteRecordName) => {
  return routeName === route.name;
};
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <TabNavView>
    <template #nav>
      <router-link
        v-for="editRoute in editRoutes"
        :key="editRoute.name"
        v-slot="{ href: linkHref, navigate }"
        :to="{ name: editRoute.name }"
        :custom="true"
      >
        <li
          role="link"
          :class="{ active: activeRoute(editRoute.name) }"
          @click="navigate"
          @keypress.enter="() => navigate"
        >
          <a :href="linkHref">{{ t(`nav.${editRoute.meta?.title}`) }}</a>
        </li>
      </router-link>
    </template>
    <template #content>
      <router-view :model="model" />
    </template>
  </TabNavView>
</template>
