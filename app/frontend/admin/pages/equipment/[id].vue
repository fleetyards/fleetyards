<script lang="ts" setup>
import { useEquipmentDetail } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

const { t } = useI18n();

const route = useRoute();

const { data: equipment, ...asyncStatus } = useEquipmentDetail(
  route.params.id as string,
);

const { updateMetaInfo } = useMetaInfo();

const title = computed(() => {
  if (route.meta.title && equipment.value) {
    return t(`title.${route.meta.title}`, {
      equipment: equipment.value.name,
    });
  }

  return undefined;
});

watch(
  [() => equipment.value, () => route.meta.title],
  () => {
    if (title.value && equipment.value) {
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
      <router-view :equipment="equipment" />
    </template>
  </AsyncData>
</template>
