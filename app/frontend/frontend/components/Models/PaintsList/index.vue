<template>
  <div class="row">
    <div class="col-12 paints">
      <hr v-if="paints?.length" />
      <h2 v-if="paints?.length" class="text-uppercase">
        {{ t("labels.model.paints") }}
      </h2>
      <transition-group
        v-if="paints?.length"
        name="fade-list"
        class="row"
        tag="div"
        appear
      >
        <div
          v-for="paint in paints"
          :key="`paint-${paint.slug}`"
          class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
        >
          <TeaserPanel :item="paint" :fullscreen="true" />
        </div>
      </transition-group>
      <Loader :loading="isLoading || isFetching" :fixed="true" />
    </div>
  </div>
</template>

<script lang="ts" setup>
import Loader from "@/shared/components/Loader/index.vue";
import TeaserPanel from "@/shared/components/TeaserPanel/index.vue";
import { useQuery } from "@tanstack/vue-query";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useI18n } from "@/frontend/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

watch(
  () => props.model,
  () => {
    refetch();
  },
);

const { models: modelsService } = useApiClient();

const {
  isLoading,
  isFetching,
  data: paints,
  refetch,
} = useQuery({
  queryKey: ["model-paints", props.model.slug],
  queryFn: () => {
    return modelsService.modelPaints({
      slug: props.model.slug,
    });
  },
  enabled: !!props.model,
});
</script>

<script lang="ts">
export default {
  name: "ModelPaintList",
};
</script>
