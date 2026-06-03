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
};

const props = withDefaults(defineProps<Props>(), {
  authenticated: false,
  resourceAccess: undefined,
});

const mobile = useMobile();
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
