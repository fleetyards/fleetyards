<script lang="ts">
export default {
  name: "BreadCrumbs",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useMobile } from "@/shared/composables/useMobile";
import { type ListMeta, type Crumb } from "./types";

type Props = {
  crumbs?: Crumb[];
  currentId?: string;
  stepperList?: string[];
  stepperListMeta?: ListMeta;
  stepperRoute?: string;
  stepperParam?: string;
  stepperExtraParams?: Record<string, string>;
};

const props = withDefaults(defineProps<Props>(), {
  crumbs: undefined,
  stepperRoute: "admin-model-edit",
  stepperParam: "id",
  stepperExtraParams: () => ({}),
});

const stepperParamsFor = (id: string) => ({
  ...props.stepperExtraParams,
  [props.stepperParam]: id,
});

const { t } = useI18n();

const { extend } = useBreadCrumbs();

const mobile = useMobile();

// A test, an embed or any page rendered without the app's navigation has no
// header to hand the trail to.
const headerAvailable = ref(false);

onMounted(() => {
  headerAvailable.value = !!document.getElementById("header-left");
});

const inHeader = computed(
  () => mobile.value && headerAvailable.value && !!props.crumbs?.length,
);

const hasStepperList = computed(
  () => !!props.stepperList && props.stepperList.length > 0,
);

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
  <!-- On a phone the trail also goes up into the header, beside the back
       button, where a page without a search leaves the row empty; whichever
       copy has room is the one shown (see the stylesheet). -->
  <Teleport v-if="inHeader" to="#header-left">
    <ol aria-label="breadcrumb" class="breadcrumb breadcrumb--header">
      <li v-for="(crumb, index) in crumbs" :key="index" class="breadcrumb-item">
        <router-link v-if="crumb.to" :to="extend(crumb.to)">
          {{ crumb.label }}
        </router-link>
        <span v-else>{{ crumb.label }}</span>
      </li>
    </ol>
  </Teleport>
  <div
    class="breadcrumbs"
    :class="{
      'breadcrumbs--movable': inHeader && !hasStepperList && !$slots.actions,
      'breadcrumbs--trail-movable': inHeader,
    }"
    v-if="crumbs?.length || hasStepperList || $slots.actions"
  >
    <!-- No home crumb: the navigation's home link sits right beside the
         trail, and the trail starts where the section does. -->
    <ol v-if="crumbs?.length" aria-label="breadcrumb" class="breadcrumb">
      <li v-for="(crumb, index) in crumbs" :key="index" class="breadcrumb-item">
        <router-link v-if="crumb.to" :to="extend(crumb.to)">
          {{ crumb.label }}
        </router-link>
        <span v-else>{{ crumb.label }}</span>
      </li>
    </ol>
    <div v-if="hasStepperList || $slots.actions" class="stepper">
      <slot name="actions" />
      <template v-if="hasStepperList">
        <router-link
          v-if="prevItem"
          :to="{ name: stepperRoute, params: stepperParamsFor(prevItem) }"
          ><i class="fa fa-chevron-left"></i
        ></router-link>
        <a v-else class="disabled" :aria-label="t('pagination.previous')"
          ><i class="fa fa-chevron-left"></i
        ></a>
        <router-link
          v-if="nextItem"
          :to="{ name: stepperRoute, params: stepperParamsFor(nextItem) }"
          ><i class="fa fa-chevron-right"></i
        ></router-link>
        <a v-else class="disabled" :aria-label="t('pagination.next')"
          ><i class="fa fa-chevron-right"></i
        ></a>
      </template>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
