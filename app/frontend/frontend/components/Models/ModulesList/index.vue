<script lang="ts">
export default {
  name: "ModelsModulesList",
};
</script>

<script lang="ts" setup>
import SectionEmpty from "@/frontend/components/Models/SectionEmpty/index.vue";
import ModelSection from "@/frontend/components/Models/Section/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import ModulePanel from "@/frontend/components/Modules/Panel/index.vue";
import {
  useModelModules as useModelModulesQuery,
  type ModelModule,
} from "@/services/fyApi";

type Props = {
  modelSlug: string;
  modelName: string;
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
  <!-- Always drawn, so the ship page's sections stand in the same place for
       every ship and a link to one has an anchor to land on before the
       request is back. -->
  <ModelSection
    anchor="modules"
    :model-slug="modelSlug"
    :title="t('labels.model.modules')"
  >
    <AsyncData :async-status="asyncStatus" hide-error>
      <template #resolved>
        <transition-group
          v-if="modules.length"
          name="fade-list"
          class="row"
          tag="div"
          appear
        >
          <div
            v-for="item in modules"
            :key="`modules-${item.id}`"
            class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
          >
            <ModulePanel :module="item" />
          </div>
        </transition-group>
        <SectionEmpty
          v-else
          :model-name="modelName"
          :section="t('labels.model.modules')"
        />
      </template>
    </AsyncData>
  </ModelSection>
</template>
