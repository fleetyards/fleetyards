<script lang="ts" setup>
import { useModelModule as useModelModuleQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

const { t } = useI18n();

const route = useRoute();

const { data: modelModule, ...asyncStatus } = useModelModuleQuery(
  route.params.id as string,
);

const { updateMetaInfo } = useMetaInfo();

const title = computed(() => {
  if (route.meta.title && modelModule.value) {
    return t(`title.${route.meta.title}`, {
      name: modelModule.value.name,
    });
  }

  return undefined;
});

watch(
  [() => modelModule.value, () => route.meta.title],
  () => {
    if (title.value && modelModule.value) {
      updateMetaInfo({
        title: title.value,
        description: modelModule.value.description,
      });
    }
  },
  { immediate: true },
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :model-module="modelModule" />
    </template>
  </AsyncData>
</template>
