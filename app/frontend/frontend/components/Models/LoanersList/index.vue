<template>
  <AsyncData :async-status="asyncStatus" hide-error inline>
    <template #resolved>
      <hr v-if="data?.items.length" />
      <ItemsList v-if="data?.items.length" :items="data.items" name="loaners" />
    </template>
  </AsyncData>
</template>

<script lang="ts" setup>
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import type { Model } from "@/services/fyApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import ItemsList from "@/frontend/components/Models/ItemsList/index.vue";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { models: modelsService } = useApiClient();

const { data, ...asyncStatus } = useQuery({
  queryKey: ["model-loaners", props.model.slug],
  queryFn: () =>
    modelsService.modelLoaners({
      slug: props.model.slug,
    }),
});
</script>

<script lang="ts">
export default {
  name: "ModelsLoanersList",
};
</script>
