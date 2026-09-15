<script lang="ts">
export default {
  name: "TabNavViewMobileDropdown",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import {
  type RouteLocationRaw,
  type RouteRecordName,
  type RouteRecordRaw,
} from "vue-router";
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
  badges?: Record<string, number>;
};

const props = withDefaults(defineProps<Props>(), {
  links: undefined,
  resourceAccess: undefined,
  badges: undefined,
});

const badgeFor = (name?: RouteRecordName) => {
  const count = name ? props.badges?.[String(name)] : undefined;

  if (!count) {
    return undefined;
  }

  return count > 99 ? "99+" : String(count);
};

// What the closed dropdown owes the reader: the rows are behind a tap, so a
// count on any of them has to reach the button that opens it.
const waiting = computed(() =>
  filteredRoutes.value
    .filter((r) => routeName(r) !== routeName(activeRoute.value ?? r))
    .reduce(
      (total, r) => total + (props.badges?.[String(routeName(r))] || 0),
      0,
    ),
);

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const visible = ref(false);
const wrapper = ref<HTMLElement | null>(null);

const filteredRoutes = computed(() => {
  return props.routes
    .filter(isTabRoute)
    .filter((r) => {
      if (props.authenticated) {
        return !r.meta?.hideWhenAuthenticated;
      }

      return !r.meta?.needsAuthentication;
    })
    .filter((r) => checkAccess(props.resourceAccess, r.meta?.access));
});

const { isActive, activeRoute } = useActiveTab(filteredRoutes);

const activeLabel = computed(() => {
  if (!activeRoute.value) return "";
  return t(`nav.${activeRoute.value.meta?.title}`);
});

const toggle = () => {
  visible.value = !visible.value;
};

const select = (r: RouteRecordRaw) => {
  visible.value = false;
  const name = routeName(r);
  if (name) {
    void router.push({ name });
  }
};

const follow = (link: TabNavLink) => {
  visible.value = false;

  void router.push(link.to as RouteLocationRaw);
};

const onDocumentClick = (event: MouseEvent) => {
  if (!visible.value) return;
  const target = event.target as HTMLElement;
  if (!wrapper.value?.contains(target)) {
    visible.value = false;
  }
};

const onKeydown = (event: KeyboardEvent) => {
  if (event.key === "Escape" && visible.value) {
    visible.value = false;
  }
};

watch(
  () => route.name,
  () => {
    visible.value = false;
  },
);

onMounted(() => {
  document.addEventListener("click", onDocumentClick);
  document.addEventListener("keydown", onKeydown);
});

onUnmounted(() => {
  document.removeEventListener("click", onDocumentClick);
  document.removeEventListener("keydown", onKeydown);
});
</script>

<template>
  <div ref="wrapper" class="tab-nav-dropdown">
    <button
      type="button"
      class="tab-nav-dropdown__trigger"
      :class="{ open: visible }"
      :aria-expanded="visible"
      aria-haspopup="listbox"
      @click="toggle"
    >
      <span class="tab-nav-dropdown__label">{{ activeLabel }}</span>
      <span v-if="waiting" class="tabs-badge">
        {{ waiting > 99 ? "99+" : waiting }}
      </span>
      <i
        class="fa-solid fa-chevron-down tab-nav-dropdown__chevron"
        aria-hidden="true"
      />
    </button>
    <Transition name="tab-nav-dropdown-panel">
      <ul v-if="visible" class="tab-nav-dropdown__panel" role="listbox">
        <li
          v-for="item in filteredRoutes"
          :key="String(routeName(item))"
          class="tab-nav-dropdown__item"
          :class="{ active: isActive(routeName(item)) }"
          role="option"
          :aria-selected="isActive(routeName(item))"
          @click="select(item)"
        >
          <span>{{ t(`nav.${item.meta?.title}`) }}</span>
          <span v-if="badgeFor(routeName(item))" class="tabs-badge">
            {{ badgeFor(routeName(item)) }}
          </span>
        </li>
        <li
          v-for="link in props.links"
          :key="link.label"
          class="tab-nav-dropdown__item tab-nav-dropdown__item--link-out"
          role="option"
          :aria-selected="false"
          @click="follow(link)"
        >
          <span>{{ link.label }}</span>
          <i
            class="fa-duotone fa-arrow-up-right-from-square"
            aria-hidden="true"
          />
        </li>
      </ul>
    </Transition>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
