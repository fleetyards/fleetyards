<script lang="ts" setup>
import { useComponent as useComponentQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

const { t } = useI18n();

const route = useRoute();

const { data: component, ...asyncStatus } = useComponentQuery(
  route.params.id as string,
);

const { updateMetaInfo } = useMetaInfo();

const title = computed(() => {
  if (route.meta.title && component.value) {
    return t(`title.${route.meta.title}`, {
      component: component.value.name,
    });
  }

  return undefined;
});

watch(
  [() => component.value, () => route.meta.title],
  () => {
    if (title.value && component.value) {
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
      <router-view :component="component" />
    </template>
  </AsyncData>
</template>
