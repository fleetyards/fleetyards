<script lang="ts">
export default {
  name: "TabNavViewItems",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type RouteRecordRaw } from "vue-router";
import { checkAccess } from "@/shared/utils/Access";
import {
  routeName,
  useActiveTab,
} from "@/shared/components/TabNavView/useActiveTab";
import { type TabNavLink } from "@/shared/components/TabNavView/types";

type Props = {
  routes: RouteRecordRaw[];
  links?: TabNavLink[];
  authenticated: boolean;
  resourceAccess?: string[];
};

const props = withDefaults(defineProps<Props>(), {
  links: undefined,
  resourceAccess: undefined,
});

const filteredRoutes = computed(() => {
  return props.routes
    .filter((route) => {
      if (props.authenticated) {
        return !route.meta?.hideWhenAuthenticated;
      }

      return !route.meta?.needsAuthentication;
    })
    .filter((route) => {
      return checkAccess(props.resourceAccess, route.meta?.access);
    });
});

const { t } = useI18n();

const { isActive } = useActiveTab(filteredRoutes);
</script>

<template>
  <router-link
    v-for="item in filteredRoutes"
    :key="routeName(item)"
    v-slot="{ href: linkHref, navigate }"
    :to="{ name: routeName(item) }"
    :custom="true"
  >
    <li
      role="link"
      :class="{ active: isActive(routeName(item)) }"
      @click="navigate"
      @keypress.enter="() => navigate"
    >
      <a :href="linkHref">{{ t(`nav.${item.meta?.title}`) }}</a>
    </li>
  </router-link>
  <template v-if="props.links?.length">
    <li class="divider" aria-hidden="true" />
    <li v-for="link in props.links" :key="link.label" class="link-out">
      <router-link :to="link.to">
        {{ link.label }}
        <i
          class="fa-duotone fa-arrow-up-right-from-square"
          aria-hidden="true"
        />
      </router-link>
    </li>
  </template>
</template>
