<template>
  <ol aria-label="breadcrumb" class="breadcrumb">
    <li class="breadcrumb-item">
      <router-link :to="{ name: 'home' }">
        {{ $t("nav.home") }}
      </router-link>
    </li>
    <li v-for="(crumb, index) in crumbs" :key="index" class="breadcrumb-item">
      <router-link :to="crumb.to">
        {{ crumb.label }}
      </router-link>
    </li>
  </ol>
</template>

<script lang="ts" setup>
import type { TBreadCrumb } from "@/@types/breadcrumbs";

type Props = {
  crumbs: TBreadCrumb[];
};

withDefaults(defineProps<Props>(), {
  crumbs: () => [],
});
</script>

<script lang="ts">
export default {
  name: "BreadCrumbs",
};
</script>
