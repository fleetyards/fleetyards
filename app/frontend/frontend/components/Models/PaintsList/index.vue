<script lang="ts">
export default {
  name: "ModelPaintList",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
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
  if (mobile.value && paint.media.storeImage?.medium) {
    return paint.media.storeImage?.medium;
  }

  if (paint.media.storeImage?.large) {
    return paint.media.storeImage?.large;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
};
</script>

<template>
  <AsyncData :async-status="asyncStatus" hide-error>
    <template #resolved>
      <div v-if="paints?.length" id="paints" class="row">
        <hr />
        <div class="col-12">
          <h2 v-if="paints?.length" id="paints" class="text-uppercase">
            {{ t("labels.model.paints") }}
          </h2>

          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="item in paints"
              :key="`paints-${item.id}`"
              class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
            >
              <Panel :bg-image="storeImage(item)">
                <PanelHeading :level="HeadingLevelEnum.H3">
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
