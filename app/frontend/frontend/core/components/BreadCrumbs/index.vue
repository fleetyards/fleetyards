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
import { useI18n } from "@/frontend/composables/useI18n";

export type Crumb = {
  to: {
    name: string;
    params?: Record<string, string | undefined>;
    hash?: string;
  };
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
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";
import Panel from "@/frontend/core/components/Panel/index.vue";

@Component({
  components: {
    Panel,
  },
})
export default class BreadCrumbs extends Vue {
  @Prop({
    default() {
      return [];
    },
  })
  crumbs!: Route[];
}
</script>
