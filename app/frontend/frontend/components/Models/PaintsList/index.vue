<script lang="ts">
export default {
  name: "ModelPaintList",
};
</script>

<script lang="ts" setup>
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
  <AsyncData :async-status="asyncStatus" hide-error>
    <template #resolved>
      <hr v-if="paints?.length" />
      <div v-if="paints?.length" id="paints" class="row">
        <div class="col-12">
          <Heading v-if="paints?.length" :level="HeadingLevelEnum.H2" hero>
            {{ t("labels.model.paints") }}
          </Heading>

          <transition-group name="fade-list" class="row" tag="div" appear>
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
        </div>
      </div>
    </template>
  </AsyncData>
</template>
