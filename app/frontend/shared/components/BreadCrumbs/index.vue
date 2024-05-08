<script lang="ts">
export default {
  name: "BreadCrumbs",
};
</script>

<script lang="ts" setup>
import {
  type RouteLocationNamedRaw,
  type RouteLocationNormalizedLoaded,
  type RouterLinkProps,
} from "vue-router";
import { useI18n } from "@/shared/composables/useI18n";

export type Crumb = {
  to: RouterLinkProps["to"];
  label?: string;
};

type Props = {
  crumbs?: Crumb[];
};

withDefaults(defineProps<Props>(), {
  crumbs: undefined,
});

const { t } = useI18n();

const router = useRouter();

const lastRoute = computed<RouteLocationNormalizedLoaded>(() => {
  return router.resolve(router.options.history.state.back as string);
});

const extend = (route: RouterLinkProps["to"]): RouterLinkProps["to"] => {
  if (
    lastRoute.value &&
    lastRoute.value.name === (route as RouteLocationNamedRaw).name
  ) {
    return {
      name: (route as RouteLocationNamedRaw).name,
      hash: (route as RouteLocationNamedRaw).hash,
      params: {
        ...lastRoute.value.params,
        ...(route as RouteLocationNamedRaw).params,
      },
      query: {
        ...lastRoute.value.query,
        ...(route as RouteLocationNamedRaw).query,
      },
    };
  }

  return route;
};
</script>

<template>
  <ol v-if="crumbs" aria-label="breadcrumb" class="breadcrumb">
    <li class="breadcrumb-item">
      <router-link :to="{ name: 'home' }">
        {{ t("nav.home") }}
      </router-link>
    </li>
    <li v-for="(crumb, index) in crumbs" :key="index" class="breadcrumb-item">
      <router-link :to="extend(crumb.to)">
        {{ crumb.label }}
      </router-link>
    </li>
  </ol>
</template>

<style lang="scss" scoped>
@import "index";
</style>
