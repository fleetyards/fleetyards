<script lang="ts">
export default {
  name: "ModelPaintList",
};
</script>

<script lang="ts" setup>
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { PanelHeadingShadowEnum } from "@/shared/components/base/Panel/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelPaint } from "@/services/fyApi";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import { useMobile } from "@/shared/composables/useMobile";
import { useModelPaints as useModelPaintsQuery } from "@/services/fyApi";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";

type Props = {
  modelSlug: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { data: paints, ...asyncStatus } = useModelPaintsQuery(props.modelSlug);

const { supported: webpSupported } = useWebpCheck();

const mobile = useMobile();

const storeImage = (paint: ModelPaint) => {
  if (mobile.value && paint.media.storeImage?.mediumUrl) {
    return paint.media.storeImage?.mediumUrl;
  }

  if (paint.media.storeImage?.largeUrl) {
    return paint.media.storeImage?.largeUrl;
  }

  if (webpSupported.value) {
    return fallbackImage;
  }

  return fallbackImageJpg;
};
</script>

<template>
  <!-- Always drawn, so the ship page's sections stand in the same place for
       every ship and a link to one has an anchor to land on before the
       request is back. -->
  <hr />
  <section id="paints" class="row">
    <div class="col-12">
      <Heading :level="HeadingLevelEnum.H2" hero>
        {{ t("labels.model.paints") }}
      </Heading>
      <AsyncData :async-status="asyncStatus" hide-error>
        <template #resolved>
          <transition-group
            v-if="paints?.length"
            name="fade-list"
            class="row"
            tag="div"
            appear
          >
            <div
              v-for="item in paints"
              :key="`paints-${item.id}`"
              class="col-12 col-md-6 col-lg-3 col-xl-2 fade-list-item"
            >
              <Panel
                :bg-image="storeImage(item)"
                :variant="PanelVariantsEnum.SLIM"
              >
                <PanelHeading
                  :shadow="PanelHeadingShadowEnum.TOP"
                  :level="HeadingLevelEnum.H3"
                >
                  {{ item.name }}
                </PanelHeading>
              </Panel>
            </div>
          </transition-group>
          <Empty
            v-else
            :variant="EmptyVariantsEnum.BOX"
            :name="t('labels.model.paints')"
            hide-actions
          />
        </template>
      </AsyncData>
    </div>
  </section>
</template>
