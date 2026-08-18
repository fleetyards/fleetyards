<script lang="ts" setup>
import { useCommodity as useCommodityQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

const { t } = useI18n();

const route = useRoute();

const { data: commodity, ...asyncStatus } = useCommodityQuery(
  route.params.id as string,
);

const { updateMetaInfo } = useMetaInfo();

const title = computed(() => {
  if (route.meta.title && commodity.value) {
    return t(`title.${route.meta.title}`, {
      commodity: commodity.value.name,
    });
  }

  return undefined;
});

watch(
  [() => commodity.value, () => route.meta.title],
  () => {
    if (title.value && commodity.value) {
      updateMetaInfo({
        title: title.value,
      });
    }
  },
  { immediate: true },
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :commodity="commodity" />
    </template>
  </AsyncData>
</template>
