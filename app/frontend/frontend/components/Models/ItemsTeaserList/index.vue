<template>
  <div class="row">
    <div class="col-12 variants">
      <h2 class="text-uppercase">
        {{ t(`labels.model.${name}`) }}
      </h2>
      <transition-group name="fade-list" class="row" tag="div" appear>
        <div
          v-for="item in items"
          :key="`${name}-${item.id}`"
          class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
        >
          <TeaserPanel :item="item" :fullscreen="fullscreen" />
        </div>
      </transition-group>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/frontend/composables/useI18n";
import TeaserPanel from "@/shared/components/TeaserPanel/index.vue";
import type { TeaserItem } from "@/shared/components/TeaserPanel/index.vue";

type Props = {
  name: string;
  items: TeaserItem[];
  fullscreen?: boolean;
};

withDefaults(defineProps<Props>(), {
  fullscreen: false,
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
