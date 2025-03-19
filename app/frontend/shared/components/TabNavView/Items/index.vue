<script lang="ts">
export default {
  name: "TabNavViewItems",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type RouteRecordName, type RouteRecordRaw } from "vue-router";

type Props = {
  routes: RouteRecordRaw[];
  authenticated: boolean;
  hasAccessTo?: (access: string) => boolean;
};

const props = defineProps<Props>();

const filteredRoutes = computed(() => {
  return props.routes
    .filter((route) => {
      if (props.authenticated) {
        return !route.meta?.hideWhenAuthenticated;
      }

      return !route.meta?.needsAuthentication;
    })
    .filter((route) => {
      if (!props.hasAccessTo) {
        return true;
      }

      if (route.meta?.access) {
        return (
          props.hasAccessTo(route.meta.access) || route.meta.access == "all"
        );
      }

      return true;
    });
});

const { t } = useI18n();

const route = useRoute();

const activeRoute = (routeName?: RouteRecordName) => {
  return routeName === route.name;
};
</script>

<template>
  <router-link
    v-for="item in filteredRoutes"
    :key="item.name"
    v-slot="{ href: linkHref, navigate }"
    :to="{ name: item.name }"
    :custom="true"
  >
    <li
      role="link"
      :class="{ active: activeRoute(item.name) }"
      @click="navigate"
      @keypress.enter="() => navigate"
    >
      <a :href="linkHref">{{ t(`nav.${item.meta?.title}`) }}</a>
    </li>
  </router-link>
</template>
