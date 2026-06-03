<script lang="ts">
export default {
  name: "TabNavViewMobileDropdown",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type RouteRecordName, type RouteRecordRaw } from "vue-router";
import { checkAccess } from "@/shared/utils/Access";

type Props = {
  routes: RouteRecordRaw[];
  authenticated: boolean;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const visible = ref(false);
const wrapper = ref<HTMLElement | null>(null);

const filteredRoutes = computed(() => {
  return props.routes
    .filter((r) => {
      if (props.authenticated) {
        return !r.meta?.hideWhenAuthenticated;
      }

      return !r.meta?.needsAuthentication;
    })
    .filter((r) => checkAccess(props.resourceAccess, r.meta?.access));
});

const routeName = (r: RouteRecordRaw) => {
  return r.name || (r.redirect as RouteRecordRaw)?.name;
};

const isActive = (tabRouteName?: RouteRecordName) => {
  if (tabRouteName === route.name) return true;

  const tabRoute = filteredRoutes.value.find(
    (r) => routeName(r) === tabRouteName,
  );
  if (!tabRoute?.children?.length) return false;

  return route.matched.some(
    (matched) => (matched.redirect as RouteRecordRaw)?.name === tabRouteName,
  );
};

const activeRoute = computed(() =>
  filteredRoutes.value.find((r) => isActive(routeName(r))),
);

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
        </li>
      </ul>
    </Transition>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
