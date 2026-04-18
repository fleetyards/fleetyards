<script lang="ts">
export default {
  name: "ModelsModulesList",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import ModulePanel from "@/frontend/components/Modules/Panel/index.vue";
import {
  useModelModules as useModelModulesQuery,
  type ModelModule,
} from "@/services/fyApi";

type Props = {
  modelSlug: string;
  modules?: ModelModule[];
};

const props = defineProps<Props>();

const { data: fetchedModules, ...asyncStatus } = useModelModulesQuery(
  props.modelSlug,
  undefined,
  { query: { enabled: !props.modules?.length } },
);

const modules = computed(
  () => props.modules || fetchedModules.value?.items || [],
);

const { t } = useI18n();
</script>

<template>
  <AsyncData :async-status="asyncStatus" hide-error>
    <template v-if="modules.length" #resolved>
      <hr />
      <div id="modules" class="row">
        <div class="col-12">
          <h2 class="text-uppercase">
            {{ t(`labels.model.modules`) }}
          </h2>
          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="item in modules"
              :key="`modules-${item.id}`"
              class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
            >
              <ModulePanel :module="item" level="h3" slim />
            </div>
          </transition-group>
        </div>
      </div>
    </template>
  </AsyncData>
</template>
