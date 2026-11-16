<script lang="ts">
export default {
  name: "ModelsBodykitsList",
};
</script>

<script lang="ts" setup>
import ModelSection from "@/frontend/components/Models/Section/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { PanelHeadingShadowEnum } from "@/shared/components/base/Panel/Heading/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useModelBodykits as useModelBodykitsQuery } from "@/services/fyApi";

type Props = {
  modelSlug: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { data, ...asyncStatus } = useModelBodykitsQuery(props.modelSlug);

const bodykits = computed(() => data.value || []);

const isEmpty = computed(
  () =>
    !bodykits.value.length &&
    (asyncStatus.isSuccess.value || asyncStatus.isError.value),
);
</script>

<template>
  <ModelSection
    v-if="!isEmpty"
    anchor="bodykits"
    :model-slug="modelSlug"
    :title="t('labels.model.bodykits')"
  >
    <AsyncData :async-status="asyncStatus" hide-error>
      <template #resolved>
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="item in bodykits"
            :key="`bodykits-${item.slot}-${item.component.id}`"
            class="col-12 col-md-6 col-lg-3 col-xl-2 fade-list-item"
            data-test="model-bodykit"
          >
            <router-link
              :to="{
                name: 'component',
                params: { slug: item.component.slug },
              }"
              class="model-bodykit__link"
            >
              <Panel
                :bg-image="item.component.imageUrl"
                :variant="PanelVariantsEnum.SLIM"
              >
                <PanelHeading
                  :shadow="PanelHeadingShadowEnum.TOP"
                  :level="HeadingLevelEnum.H3"
                >
                  {{ item.component.name }}
                  <Pill
                    v-if="item.stock"
                    :variant="PillVariantsEnum.NEUTRAL"
                    class="model-bodykit__stock"
                  >
                    {{ t("labels.model.bodykitStock") }}
                  </Pill>
                </PanelHeading>
              </Panel>
            </router-link>
          </div>
        </transition-group>
      </template>
    </AsyncData>
  </ModelSection>
</template>

<style lang="scss" scoped>
.model-bodykit__link {
  display: block;
  color: inherit;
  text-decoration: none;
}

.model-bodykit__stock {
  margin-left: 8px;
}
</style>
