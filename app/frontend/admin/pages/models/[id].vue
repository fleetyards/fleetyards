<script lang="ts" setup>
import { useModel as useModelQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

const { t } = useI18n();

const route = useRoute();

const { data: model, ...asyncStatus } = useModelQuery(
  route.params.id as string,
);

const { updateMetaInfo } = useMetaInfo();

const title = computed(() => {
  if (route.meta.title && model.value && model.value.manufacturer) {
    return t(`title.${route.meta.title}`, {
      manufacturer: model.value.manufacturer.code,
      model: model.value.name,
    });
  }

  return undefined;
});

watch(
  () => model.value,
  () => {
    if (title.value && model.value) {
      updateMetaInfo({
        title: title.value,
        description: model.value.description,
      });
    }
  },
  { immediate: true },
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :model="model" />
    </template>
  </AsyncData>
</template>
