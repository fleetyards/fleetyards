<template>
  <AsyncData :async-status="asyncStatus" hide-error inline>
    <template v-if="upgrades?.length" #resolved>
      <hr />
      <div id="upgrades" class="row">
        <div class="col-12">
          <h2 class="text-uppercase">
            {{ t(`labels.model.upgrades`) }}
          </h2>
          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="item in upgrades"
              :key="`upgrades-${item.id}`"
              class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
            >
              <TeaserPanel :item="item" level="h3" />
            </div>
          </transition-group>
        </div>
      </div>
    </template>
  </AsyncData>
</template>

<script lang="ts" setup>
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import TeaserPanel from "@/shared/components/TeaserPanel2/index.vue";

type Props = {
  modelSlug: string;
};

const props = defineProps<Props>();

const { models: modelsService } = useApiClient();

const { data: upgrades, ...asyncStatus } = useQuery({
  queryKey: ["model-upgrades", props.modelSlug],
  queryFn: () =>
    modelsService.modelUpgrades({
      slug: props.modelSlug,
    }),
});

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "ModelsModulesList",
};
</script>
