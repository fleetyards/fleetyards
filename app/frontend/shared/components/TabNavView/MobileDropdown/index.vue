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
import { type TabNavViewAnchorItem } from "@/shared/components/TabNavView/AnchorItems/index.vue";

type Props = {
  routes?: RouteRecordRaw[];
  // In-page tabs that switch content without navigating, in place of routes.
  anchors?: TabNavViewAnchorItem[];
  activeId?: string;
  links?: TabNavLink[];
  authenticated?: boolean;
  resourceAccess?: string[];
  // Mirrors AccessCheck: the flag sits beside the privilege list rather than
  // inside it, so a tab gated on one is only reachable by checking both.
  superAdmin?: boolean;
  badges?: Record<string, number>;
};

const props = withDefaults(defineProps<Props>(), {
  routes: undefined,
  anchors: undefined,
  activeId: undefined,
  authenticated: false,
  links: undefined,
  resourceAccess: undefined,
  superAdmin: false,
  badges: undefined,
});

const emit = defineEmits<{
  "update:activeId": [value: string];
}>();

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

const panel = ref<HTMLElement | null>(null);

const filteredRoutes = computed(() => {
  return (props.routes ?? [])
    .filter(isTabRoute)
    .filter((r) => {
      if (props.authenticated) {
        return !r.meta?.hideWhenAuthenticated;
      }

      return !r.meta?.needsAuthentication;
    })
    .filter(
      (r) =>
        props.superAdmin || checkAccess(props.resourceAccess, r.meta?.access),
    );
});

const { isActive, activeRoute } = useActiveTab(filteredRoutes);

const activeAnchor = computed(() =>
  props.anchors?.find((item) => item.id === props.activeId),
);

const activeLabel = computed(() => {
  if (props.anchors) return activeAnchor.value?.label ?? "";
  if (!activeRoute.value) return "";
  return t(`nav.${activeRoute.value.meta?.title}`);
});

// The panel hangs below the trigger, and inside a scrolling box -- a modal's
// body on a phone -- the rows past its edge are cut off rather than reached.
const toggle = async () => {
  visible.value = !visible.value;
  if (!visible.value) return;

  await nextTick();
  panel.value?.scrollIntoView?.({ block: "nearest" });
};

const select = (r: RouteRecordRaw) => {
  visible.value = false;
  const name = routeName(r);
  if (name) {
    void router.push({ name });
  }
};

const selectAnchor = (item: TabNavViewAnchorItem) => {
  if (item.disabled) return;

  visible.value = false;
  emit("update:activeId", item.id);
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
      <span
        v-if="anchors?.some((item) => item.invalid)"
        class="tab-nav-dropdown__error"
        aria-hidden="true"
      />
      <span v-if="waiting" class="tabs-badge">
        {{ waiting > 99 ? "99+" : waiting }}
      </span>
      <i
        class="fa-solid fa-chevron-down tab-nav-dropdown__chevron"
        aria-hidden="true"
      />
    </button>
    <Transition name="tab-nav-dropdown-panel">
      <ul
        v-if="visible"
        ref="panel"
        class="tab-nav-dropdown__panel"
        role="listbox"
      >
        <li
          v-for="item in props.anchors"
          :key="item.id"
          class="tab-nav-dropdown__item"
          :class="{
            active: item.id === props.activeId,
            disabled: item.disabled,
            'has-errors': item.invalid,
          }"
          role="option"
          :aria-selected="item.id === props.activeId"
          :aria-disabled="item.disabled || undefined"
          :data-test="`tab-anchor-option-${item.id}`"
          :tabindex="item.disabled ? -1 : 0"
          @click="selectAnchor(item)"
          @keydown.enter.prevent="selectAnchor(item)"
          @keydown.space.prevent="selectAnchor(item)"
        >
          <span>{{ item.label }}</span>
          <span
            v-if="item.invalid"
            class="tab-nav-dropdown__error"
            aria-hidden="true"
          />
        </li>
        <li
          v-for="item in filteredRoutes"
          :key="String(routeName(item))"
          class="tab-nav-dropdown__item"
          :class="{ active: isActive(routeName(item)) }"
          role="option"
          :aria-selected="isActive(routeName(item))"
          tabindex="0"
          @click="select(item)"
          @keydown.enter.prevent="select(item)"
          @keydown.space.prevent="select(item)"
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
          tabindex="0"
          @click="follow(link)"
          @keydown.enter.prevent="follow(link)"
          @keydown.space.prevent="follow(link)"
        >
          <span>{{ link.label }}</span>
          <i
            class="fa-duotone fa-arrow-up-right-from-square"
            aria-hidden="true"
          />
        </li>
        <slot name="after" />
      </ul>
    </Transition>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
