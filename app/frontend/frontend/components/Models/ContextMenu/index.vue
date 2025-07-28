<script lang="ts">
export default {
  name: "VehicleContextMenu",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import type { Model } from "@/services/fyApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import rsiLogo from "@/images/rsi_logo.png";

type Props = {
  model: Model;
  variant?: BtnVariantsEnum;
  size?: BtnSizesEnum;
  inGroup?: boolean;
};

withDefaults(defineProps<Props>(), {
  variant: BtnVariantsEnum.DEFAULT,
  size: BtnSizesEnum.SMALL,
  inGroup: false,
});

const { t } = useI18n();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown
    :size="size"
    :variant="variant"
    class="panel-edit-menu"
    data-test="vehicle-menu"
    expand-left
    expand-bottom
    inline
  >
    <Btn
      v-if="mobile"
      :to="{
        name: 'ship',
        params: {
          slug: model.slug,
        },
      }"
      :size="BtnSizesEnum.SMALL"
    >
      <i class="fad fa-starship" />
      <span>{{ t("actions.showDetailPage") }}</span>
    </Btn>
    <Btn
      :size="BtnSizesEnum.SMALL"
      :href="model.links.storeUrl"
      style="flex-grow: 3"
    >
      <img :src="rsiLogo" alt="RSI Logo" />
      <span>{{ t("actions.model.store") }}</span>
    </Btn>
    <Btn
      v-if="model.hasImages"
      :to="{
        name: 'ship-images',
        params: { slug: model.slug },
      }"
      :size="BtnSizesEnum.SMALL"
    >
      <i class="fa fa-images" />
      <span>{{ t("nav.images") }}</span>
    </Btn>
    <Btn
      v-if="model.hasVideos"
      :to="{
        name: 'ship-videos',
        params: { slug: model.slug },
      }"
      :size="BtnSizesEnum.SMALL"
    >
      <i class="fal fa-video" />
      <span>{{ t("nav.videos") }}</span>
    </Btn>
    <Btn
      v-if="model.brochure"
      :href="model.brochure"
      :size="BtnSizesEnum.SMALL"
    >
      <i class="fal fa-download" />
      <span>{{ t("labels.model.brochure") }}</span>
    </Btn>
    <Btn
      :to="{
        name: 'compare',
        query: { models: [model.slug] },
      }"
      data-test="compare"
      :size="BtnSizesEnum.SMALL"
    >
      <i class="fal fa-code-compare" />
      <span>{{ t("actions.compare.ships") }}</span>
    </Btn>
    <Btn
      v-if="model.links.salesPageUrl"
      :href="model.links.salesPageUrl"
      :size="BtnSizesEnum.SMALL"
    >
      <i class="fad fa-megaphone" />
      <span>{{ t("labels.model.salesPage") }}</span>
    </Btn>
  </BtnDropdown>
</template>
