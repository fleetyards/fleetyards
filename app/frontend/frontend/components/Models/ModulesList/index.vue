<template>
  <AsyncData :async-status="asyncStatus" hide-error inline>
    <template #resolved>
      <hr v-if="data?.items.length" />
      <ItemsTeaserList
        v-if="data?.items.length"
        :items="data.items"
        name="upgrades"
      />
    </template>
  </AsyncData>
</template>

<script lang="ts" setup>
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import AsyncData from "@/shared/components/AsyncData.vue";
import ItemsTeaserList from "@/frontend/components/Models/ItemsTeaserList/index.vue";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { models: modelsService } = useApiClient();

const { data, ...asyncStatus } = useQuery({
  queryKey: ["model-modules", props.model.slug],
  queryFn: () =>
    modelsService.modelModules({
      slug: props.model.slug,
    }),
});
</script>

<script lang="ts">
export default {
  name: "ModelsModulesList",
};
</script>
