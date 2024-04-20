<template>
  <AsyncData :async-status="asyncStatus" hide-error inline>
    <template v-if="modules?.items.length" #resolved>
      <hr />
      <div id="modules" class="row">
        <div class="col-12">
          <h2 class="text-uppercase">
            {{ t(`labels.model.modules`) }}
          </h2>
          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="item in modules.items"
              :key="`modules-${item.id}`"
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
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import TeaserPanel from "@/shared/components/TeaserPanel/index.vue";
import { useModelQueries } from "@/frontend/composables/useModelQueries";

type Props = {
  modelSlug: string;
};

const props = defineProps<Props>();

const { modulesQuery } = useModelQueries(props.modelSlug);

const { data: modules, ...asyncStatus } = modulesQuery();

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "ModelsModulesList",
};
</script>
