<script lang="ts">
export default {
  name: "ModelsVariantsList",
};
</script>

<script lang="ts" setup>
import ModelSection from "@/frontend/components/Models/Section/index.vue";
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

// Drawn while its request is out, so a link to the section has somewhere to
// land; a ship with nothing to show here loses the section once it is back.
const isEmpty = computed(
  () =>
    !variants.value?.items.length &&
    (asyncStatus.isSuccess.value || asyncStatus.isError.value),
);
</script>

<template>
  <ModelSection
    v-if="!isEmpty"
    anchor="variants"
    :model-slug="modelSlug"
    :title="t('labels.model.variants')"
  >
    <AsyncData :async-status="asyncStatus" hide-error>
      <template #resolved>
        <transition-group
          v-if="variants?.items.length"
          name="fade-list"
          class="row"
          tag="div"
          appear
        >
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
      </template>
    </AsyncData>
  </ModelSection>
</template>
