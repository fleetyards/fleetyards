<template>
  <Modal :title="title">
    <div v-if="component" class="col-12 metrics-block">
      <div class="row">
        <div class="col-6">
          <div class="metrics-label">{{ t("component.size") }}:</div>
          <div class="metrics-value">
            {{ component.size }}
          </div>
          <div class="metrics-label">{{ t("component.manufacturer") }}:</div>
          <div class="metrics-value" v-html="component.manufacturer?.name" />
        </div>
        <div v-if="hardpoint.type === 'missiles'" class="col-6">
          <div class="metrics-label">{{ t("labels.hardpoint.rackSize") }}:</div>
          <div class="metrics-value">
            {{ hardpoint.size }}
          </div>
        </div>
        <div v-if="hardpoint.details" class="col-6">
          <div class="metrics-label">{{ t("labels.hardpoint.details") }}:</div>
          <div class="metrics-value">
            {{ hardpoint.details }}
          </div>
        </div>
      </div>
    </div>
    <div class="clearfix" />
  </Modal>
</template>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import type { ModelHardpoint } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

type Props = {
  hardpoint: ModelHardpoint;
};

const props = defineProps<Props>();

const component = computed(() => {
  return props.hardpoint.component;
});

const title = computed(() => {
  return component.value?.name || "";
});
</script>

<script lang="ts">
export default {
  name: "ModelHardpointsComponentModal",
};
</script>
