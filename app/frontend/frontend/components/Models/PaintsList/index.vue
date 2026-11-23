<script lang="ts">
export default {
  name: "ModelPaintList",
};
</script>

<script lang="ts" setup>
import ModelSection from "@/frontend/components/Models/Section/index.vue";
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
import { PanelTonesEnum } from "@/shared/components/base/Panel/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useHangarPaints } from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";

type Props = {
  modelSlug: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { data: paints, ...asyncStatus } = useModelPaintsQuery(props.modelSlug);

const sessionStore = useSessionStore();

const { data: ownedPaintIds } = useHangarPaints({
  query: {
    enabled: computed(() => sessionStore.isAuthenticated),
  },
});

const ownedIds = computed(() => new Set(ownedPaintIds.value ?? []));

const owned = (paint: ModelPaint) => ownedIds.value.has(paint.id);

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

// Drawn while its request is out, so a link to the section has somewhere to
// land; a ship with nothing to show here loses the section once it is back.
const isEmpty = computed(
  () =>
    !paints.value?.length &&
    (asyncStatus.isSuccess.value || asyncStatus.isError.value),
);
</script>

<template>
  <ModelSection
    v-if="!isEmpty"
    anchor="paints"
    :model-slug="modelSlug"
    :title="t('labels.model.paints')"
  >
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
            data-test="model-paint"
          >
            <Panel
              :bg-image="storeImage(item)"
              :variant="PanelVariantsEnum.SLIM"
              :tone="
                owned(item) ? PanelTonesEnum.SUCCESS : PanelTonesEnum.NEUTRAL
              "
            >
              <Pill
                v-if="owned(item)"
                :variant="PillVariantsEnum.SUCCESS"
                class="model-paint-owned"
                data-test="model-paint-owned"
              >
                {{ t("labels.model.paintOwned") }}
              </Pill>
              <PanelHeading
                :shadow="PanelHeadingShadowEnum.TOP"
                :level="HeadingLevelEnum.H3"
              >
                {{ item.name }}
              </PanelHeading>
            </Panel>
          </div>
        </transition-group>
      </template>
    </AsyncData>
  </ModelSection>
</template>

<style scoped>
.model-paint-owned {
  position: absolute;
  top: 8px;
  right: 8px;
  z-index: 1;
}
</style>
