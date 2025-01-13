<script lang="ts" setup>
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { routes as settingsRoutes } from "./settings/routes";
import { type RouteRecordName } from "vue-router";

const { t } = useI18n();

const route = useRoute();

const activeRoute = (routeName?: RouteRecordName) => {
  return routeName === route.name;
};
</script>

<template>
  <TabNavView>
    <template #nav>
      <router-link
        v-for="settingsRoute in settingsRoutes"
        :key="settingsRoute.name"
        v-slot="{ href: linkHref, navigate }"
        :to="{ name: settingsRoute.name }"
        :custom="true"
      >
        <li
          role="link"
          :class="{ active: activeRoute(settingsRoute.name) }"
          @click="navigate"
          @keypress.enter="() => navigate"
        >
          <a :href="linkHref">{{ t(`nav.${settingsRoute.meta?.title}`) }}</a>
        </li>
      </router-link>
    </template>
    <template #content>
      <router-view />
    </template>
  </TabNavView>
</template>
