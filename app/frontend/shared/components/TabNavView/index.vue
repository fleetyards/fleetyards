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

type Props = {
  routes: RouteRecordRaw[];
  authenticated?: boolean;
  resourceAccess?: string[];
  activeKey?: string;
};

const props = withDefaults(defineProps<Props>(), {
  authenticated: false,
  resourceAccess: undefined,
  activeKey: undefined,
});

const mobile = useMobile();
const tabsEl = ref<HTMLElement | null>(null);
const route = useRoute();

const scrollToActive = (smooth = true) => {
  if (!mobile.value) return;

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
  <div class="row">
    <div class="col-12 col-md-9">
      <slot name="content">
        <router-view />
      </slot>
    </div>
    <div class="col-12 col-md-3 tabs-wrapper">
      <TabNavViewMobileDropdown
        v-if="mobile"
        :routes="props.routes"
        :authenticated="props.authenticated"
        :resource-access="props.resourceAccess"
      />
      <ul v-else class="tabs">
        <slot name="nav">
          <TabNavViewItems
            :routes="props.routes"
            :authenticated="props.authenticated"
            :resource-access="props.resourceAccess"
          />
        </slot>
      </ul>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
