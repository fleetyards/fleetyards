<template>
  <ol v-if="crumbs" aria-label="breadcrumb" class="breadcrumb">
    <li class="breadcrumb-item">
      <router-link :to="{ name: 'home' }">
        {{ t("nav.home") }}
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
import { type RouteLocationRaw } from "vue-router";
import { useI18n } from "@/shared/composables/useI18n";

export type Crumb = {
  to: RouteLocationRaw;
  label?: string;
};

type Props = {
  crumbs?: Crumb[];
};

withDefaults(defineProps<Props>(), {
  crumbs: undefined,
});

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "BreadCrumbs",
};
</script>
