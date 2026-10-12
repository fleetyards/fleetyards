<script lang="ts">
export default {
  name: "ModelsModulesList",
};
</script>

<script lang="ts" setup>
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
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
  <!-- Always drawn, so the ship page's sections stand in the same place for
       every ship and a link to one has an anchor to land on before the
       request is back. -->
  <hr />
  <section id="modules" class="row">
    <div class="col-12">
      <Heading :level="HeadingLevelEnum.H2" hero>
        {{ t("labels.model.modules") }}
      </Heading>
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
          <Empty
            v-else
            :variant="EmptyVariantsEnum.BOX"
            :name="t('labels.model.modules')"
            hide-actions
          />
        </template>
      </AsyncData>
    </div>
  </section>
</template>
