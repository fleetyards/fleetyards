<script lang="ts">
export default {
  name: "TabNavViewItems",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type RouteRecordName, type RouteRecordRaw } from "vue-router";
import { checkAccess } from "@/shared/utils/Access";
import {
  isTabRoute,
  routeName,
  useActiveTab,
} from "@/shared/components/TabNavView/useActiveTab";
import { type TabNavLink } from "@/shared/components/TabNavView/types";

type Props = {
  routes: RouteRecordRaw[];
  links?: TabNavLink[];
  authenticated: boolean;
  resourceAccess?: string[];
  // Mirrors AccessCheck: the flag sits beside the privilege list rather than
  // inside it, so a tab gated on one is only reachable by checking both.
  superAdmin?: boolean;
  // Counts to show beside a tab, by route name. The nav badge's cap, so a tab
  // cannot be widened by a number nobody reads precisely anyway.
  badges?: Record<string, number>;
};

const props = withDefaults(defineProps<Props>(), {
  links: undefined,
  resourceAccess: undefined,
  superAdmin: false,
  badges: undefined,
});

const badgeFor = (name?: RouteRecordName) => {
  const count = name ? props.badges?.[String(name)] : undefined;

  if (!count) {
    return undefined;
  }

  return count > 99 ? "99+" : String(count);
};

const filteredRoutes = computed(() => {
  return props.routes
    .filter(isTabRoute)
    .filter((route) => {
      if (props.authenticated) {
        return !route.meta?.hideWhenAuthenticated;
      }

      return !route.meta?.needsAuthentication;
    })
    .filter((route) => {
      return (
        props.superAdmin ||
        checkAccess(props.resourceAccess, route.meta?.access)
      );
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
      <a :href="linkHref">
        {{ t(`nav.${item.meta?.title}`) }}
        <span v-if="badgeFor(routeName(item))" class="tabs-badge">
          {{ badgeFor(routeName(item)) }}
        </span>
      </a>
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
