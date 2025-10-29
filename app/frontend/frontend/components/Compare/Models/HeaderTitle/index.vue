<script lang="ts">
export default {
  name: "ModelsCompareHeaderTitle",
};
</script>

<script lang="ts" setup>
import CompareModelsRow from "@/frontend/components/Compare/Models/Row/index.vue";
import { type Model } from "@/services/fyApi";

type Props = {
  models: Model[];
  slim?: boolean;
};

withDefaults(defineProps<Props>(), {
  slim: false,
});
</script>

<template>
  <CompareModelsRow
    :models="models"
    :slim="slim"
    row-key="title"
    headline
    sticky
  >
    <template #default="{ model }">
      <div class="text-center compare-title">
        <router-link :to="{ name: 'ship', params: { slug: model.slug } }">
          <strong>{{ model.name }}</strong>
        </router-link>
      </div>
    </template>
  </CompareModelsRow>
</template>

<style lang="scss" scoped>
@import "index";
</style>
