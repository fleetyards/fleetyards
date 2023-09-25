<template>
  <div class="row">
    <div class="col-12 variants">
      <h2 class="text-uppercase">
        {{ t(`labels.model.${name}`) }}
      </h2>
      <transition-group name="fade-list" class="row" tag="div" appear>
        <div
          v-for="item in items"
          :key="`${name}-${item.slug}`"
          class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
        >
          <ModelPanel :model="item" :details="true" />
        </div>
      </transition-group>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/frontend/composables/useI18n";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import type { Model } from "@/services/fyApi";

type Props = {
  name: string;
  items: Model[];
  details?: boolean;
};

withDefaults(defineProps<Props>(), {
  details: false,
});

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "ModelsItemList",
};
</script>

<style scoped lang="scss">
@import "index.scss";
</style>
