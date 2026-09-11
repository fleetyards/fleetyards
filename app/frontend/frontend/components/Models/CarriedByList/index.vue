<script lang="ts">
export default {
  name: "ModelsCarriedByList",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { PanelHeadingShadowEnum } from "@/shared/components/base/Panel/Heading/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { type ModelExtendedCarriedByItem } from "@/services/fyApi";

type Props = {
  carriedBy: ModelExtendedCarriedByItem[];
};

defineProps<Props>();

const { t } = useI18n();

const mobile = useMobile();

const { supported: webpSupported } = useWebpCheck();

// The same ladder the paints panels walk: the smaller picture on a phone, the
// larger one otherwise, and a fallback in the format the browser can read.
const storeImage = (item: ModelExtendedCarriedByItem) => {
  if (mobile.value && item.storeImage?.mediumUrl) {
    return item.storeImage.mediumUrl;
  }

  if (item.storeImage?.largeUrl) {
    return item.storeImage.largeUrl;
  }

  return webpSupported.value ? fallbackImage : fallbackImageJpg;
};
</script>

<template>
  <template v-if="carriedBy.length">
    <hr />
    <div id="carried-by" class="row">
      <div class="col-12">
        <Heading :level="HeadingLevelEnum.H2" hero>
          {{ t("labels.model.carriedBy") }}
        </Heading>

        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="item in carriedBy"
            :key="`carried-by-${item.slug}`"
            class="col-12 col-md-6 col-lg-3 col-xl-2 fade-list-item"
          >
            <router-link
              class="carried-by__link"
              :to="{ name: 'ship', params: { slug: item.slug } }"
            >
              <Panel :bg-image="storeImage(item)">
                <PanelHeading
                  :shadow="PanelHeadingShadowEnum.TOP"
                  :level="HeadingLevelEnum.H3"
                >
                  {{ item.name }}

                  <template #actions>
                    <Pill :variant="PillVariantsEnum.NEUTRAL" uppercase>
                      {{ t(`labels.dockTypes.${item.dockType}`) }}
                    </Pill>
                  </template>
                </PanelHeading>
              </Panel>
            </router-link>
          </div>
        </transition-group>
      </div>
    </div>
  </template>
</template>

<style lang="scss" scoped>
.carried-by__link {
  // The documented knob for the image region's floor, which is 286px by
  // default. A carrier list runs to three figures on a big ship, so a full-size
  // card per entry would be a wall. 160px matches the mission ShipCard.
  --panel-image-height: 160px;

  display: block;
  text-decoration: none;
}
</style>
