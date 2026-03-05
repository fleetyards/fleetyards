<script lang="ts">
export default {
  name: "BreadCrumbs",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { type ListMeta, type Crumb } from "./types";

type Props = {
  crumbs?: Crumb[];
  currentId?: string;
  stepperList?: string[];
  stepperListMeta?: ListMeta;
};

const props = withDefaults(defineProps<Props>(), {
  crumbs: undefined,
});

const { t } = useI18n();

const { extend } = useBreadCrumbs();

const prevItem = computed(() => {
  const index = props.stepperList?.findIndex((id) => id === props.currentId);

  if (index !== undefined && index > 0 && props.stepperList) {
    return props.stepperList[index - 1];
  }
});

const nextItem = computed(() => {
  const index = props.stepperList?.findIndex((id) => id === props.currentId);

  if (index !== undefined && index >= 0 && props.stepperList) {
    return props.stepperList[index + 1];
  }
});
</script>

<template>
  <div class="breadcrumbs" v-if="crumbs || stepperList">
    <ol v-if="crumbs" aria-label="breadcrumb" class="breadcrumb">
      <li class="breadcrumb-item">
        <router-link :to="{ name: 'home' }">
          {{ t("nav.home") }}
        </router-link>
      </li>
      <li v-for="(crumb, index) in crumbs" :key="index" class="breadcrumb-item">
        <router-link v-if="crumb.to" :to="extend(crumb.to)">
          {{ crumb.label }}
        </router-link>
        <span v-else>{{ crumb.label }}</span>
      </li>
    </ol>
    <div v-if="stepperList" class="stepper">
      <router-link
        v-if="prevItem"
        :to="{ name: 'admin-model-edit', params: { id: prevItem } }"
        ><i class="fa fa-chevron-left"></i
      ></router-link>
      <a v-else class="disabled" :aria-label="t('pagination.previous')"
        ><i class="fa fa-chevron-left"></i
      ></a>
      <router-link
        v-if="nextItem"
        :to="{ name: 'admin-model-edit', params: { id: nextItem } }"
        ><i class="fa fa-chevron-right"></i
      ></router-link>
      <a v-else class="disabled" :aria-label="t('pagination.next')"
        ><i class="fa fa-chevron-right"></i
      ></a>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
