<script lang="ts">
export default {
  name: "ModelsVariantsList",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import { useModelVariants as useModelVariantsQuery } from "@/services/fyApi";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";

type Props = {
  modelSlug: string;
};

const props = defineProps<Props>();

const { data: variants, ...asyncStatus } = useModelVariantsQuery(
  props.modelSlug,
);

const { t } = useI18n();
</script>

<template>
  <AsyncData :async-status="asyncStatus" hide-error>
    <template v-if="variants?.items.length" #resolved>
      <hr />
      <div id="variants" class="row">
        <div class="col-12 variants">
          <Heading :level="HeadingLevelEnum.H2" hero>
            {{ t(`labels.model.variants`) }}
          </Heading>
          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="item in variants.items"
              :key="`variants-${item.slug}`"
              class="col-12 col-md-6 col-lg-3 col-xl-2 fade-list-item"
            >
              <ModelPanel
                :model="item"
                :details="true"
                :level="HeadingLevelEnum.H3"
              />
            </div>
          </transition-group>
        </div>
      </div>
    </template>
  </AsyncData>
</template>
