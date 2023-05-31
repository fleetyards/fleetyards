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
          <div class="metrics-value">
            {{ component.manufacturer.name }}
          </div>
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
import Modal from "@/frontend/core/components/AppModal/Inner/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";

type Props = {
  hardpoint: TModelHardpoint;
};

const props = defineProps<Props>();

const { t } = useI18n();

const title = computed(() => {
  return component.value.name || "";
});

const component = computed(() => {
  return props.hardpoint.component;
});
</script>

<script lang="ts">
export default {
  name: "ComponentModal",
};
</script>
