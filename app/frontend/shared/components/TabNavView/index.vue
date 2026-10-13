<script lang="ts">
export default {
  name: "TabNavView",
};
</script>

<script lang="ts" setup>
import { type RouteRecordRaw } from "vue-router";
import { useMobile } from "@/shared/composables/useMobile";
import TabNavViewItems from "@/shared/components/TabNavView/Items/index.vue";
import TabNavViewMobileDropdown from "@/shared/components/TabNavView/MobileDropdown/index.vue";
import TabNavViewAnchorItems, {
  type TabNavViewAnchorItem,
} from "@/shared/components/TabNavView/AnchorItems/index.vue";
import { type TabNavLink } from "@/shared/components/TabNavView/types";

type Props = {
  routes?: RouteRecordRaw[];
  links?: TabNavLink[];
  authenticated?: boolean;
  resourceAccess?: string[];
  // Mirrors AccessCheck: the flag sits beside the privilege list rather than
  // inside it, so a tab gated on one is only reachable by checking both.
  superAdmin?: boolean;
  activeKey?: string;
  // Counts to show beside a tab, by route name.
  badges?: Record<string, number>;
  // In-page tabs that switch content without navigating, in place of routes.
  // The active one is `activeKey`.
  anchors?: TabNavViewAnchorItem[];
  // A strip above the content instead of the column beside it, for a page
  // whose header already spans the full width.
  horizontal?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  routes: undefined,
  links: undefined,
  authenticated: false,
  resourceAccess: undefined,
  superAdmin: false,
  activeKey: undefined,
  badges: undefined,
  anchors: undefined,
  horizontal: false,
});

const emit = defineEmits<{
  "update:activeKey": [value: string];
}>();

const mobile = useMobile();

const collapsed = computed(
  () => mobile.value && !!(props.routes?.length || props.anchors?.length),
);
const tabsEl = ref<HTMLElement | null>(null);
const route = useRoute();

const scrollToActive = (smooth = true) => {
  if (!props.horizontal || collapsed.value) return;

  const container = tabsEl.value;
  if (!container) return;

  const activeEl = container.querySelector<HTMLElement>("li.active");
  if (!activeEl) return;

  const containerRect = container.getBoundingClientRect();
  const elRect = activeEl.getBoundingClientRect();

  const scrollLeft =
    activeEl.offsetLeft - containerRect.width / 2 + elRect.width / 2;

  container.scrollTo({
    left: scrollLeft,
    behavior: smooth ? "smooth" : "instant",
  });
};

onMounted(() => {
  void nextTick(() => scrollToActive(false));
});

watch(
  () => (props.activeKey !== undefined ? props.activeKey : route.name),
  () => {
    void nextTick(() => scrollToActive(true));
  },
);
</script>

<template>
  <div v-if="props.horizontal" class="tab-nav-horizontal">
    <TabNavViewMobileDropdown
      v-if="collapsed"
      class="tab-nav-horizontal__dropdown"
      :routes="props.routes"
      :anchors="props.anchors"
      :active-id="props.activeKey"
      :links="props.links"
      :authenticated="props.authenticated"
      :resource-access="props.resourceAccess"
      :super-admin="props.superAdmin"
      :badges="props.badges"
      @update:active-id="emit('update:activeKey', $event)"
    >
      <template v-if="$slots['nav-after']" #after>
        <slot name="nav-after" />
      </template>
    </TabNavViewMobileDropdown>
    <ul
      v-else
      ref="tabsEl"
      class="tabs tabs--horizontal"
      :role="props.anchors ? 'tablist' : undefined"
      :aria-orientation="props.anchors ? 'horizontal' : undefined"
    >
      <slot name="nav">
        <TabNavViewAnchorItems
          v-if="props.anchors"
          :items="props.anchors"
          :active-id="props.activeKey"
          @update:active-id="emit('update:activeKey', $event)"
        />
        <TabNavViewItems
          v-else-if="props.routes"
          :routes="props.routes"
          :links="props.links"
          :authenticated="props.authenticated"
          :resource-access="props.resourceAccess"
          :super-admin="props.superAdmin"
          :badges="props.badges"
        />
      </slot>
      <slot name="nav-after" />
    </ul>
    <slot name="content">
      <router-view />
    </slot>
  </div>
  <div v-else class="row">
    <div class="col-12 col-md-9">
      <slot name="content">
        <router-view />
      </slot>
    </div>
    <div class="col-12 col-md-3 tabs-wrapper">
      <TabNavViewMobileDropdown
        v-if="collapsed"
        :routes="props.routes"
        :anchors="props.anchors"
        :active-id="props.activeKey"
        :links="props.links"
        :authenticated="props.authenticated"
        :resource-access="props.resourceAccess"
        :super-admin="props.superAdmin"
        :badges="props.badges"
        @update:active-id="emit('update:activeKey', $event)"
      >
        <template v-if="$slots['nav-after']" #after>
          <slot name="nav-after" />
        </template>
      </TabNavViewMobileDropdown>
      <ul
        v-else
        class="tabs"
        :role="props.anchors ? 'tablist' : undefined"
        :aria-orientation="props.anchors ? 'vertical' : undefined"
      >
        <slot name="nav">
          <TabNavViewAnchorItems
            v-if="props.anchors"
            :items="props.anchors"
            :active-id="props.activeKey"
            @update:active-id="emit('update:activeKey', $event)"
          />
          <TabNavViewItems
            v-else-if="props.routes"
            :routes="props.routes"
            :links="props.links"
            :authenticated="props.authenticated"
            :resource-access="props.resourceAccess"
            :super-admin="props.superAdmin"
            :badges="props.badges"
          />
        </slot>
        <slot name="nav-after" />
      </ul>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
