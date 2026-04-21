<script lang="ts">
export default {
  name: "ModuleSelectModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelImage from "@/shared/components/base/Panel/Image/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelModule } from "@/services/fyApi";
import { PanelAlignmentsEnum } from "@/shared/components/base/Panel/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import { useMobile } from "@/shared/composables/useMobile";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";

type Props = {
  modules: ModelModule[];
  selectedModuleSlug?: string;
  onSelect: (mod: ModelModule | null) => void;
};

const props = defineProps<Props>();

const { t } = useI18n();

const comlink = useComlink();

const { supported: webpSupported } = useWebpCheck();

const mobile = useMobile();

const storeImage = (mod: ModelModule) => {
  if (mobile.value && mod.media.storeImage?.mediumUrl) {
    return mod.media.storeImage?.mediumUrl;
  }

  if (mod.media.storeImage?.smallUrl) {
    return mod.media.storeImage?.smallUrl;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
};

const selectModule = (mod: ModelModule) => {
  props.onSelect(mod);
  comlink.emit("close-modal");
};

const clearModule = () => {
  props.onSelect(null);
  comlink.emit("close-modal");
};

const isSelected = (mod: ModelModule) => mod.slug === props.selectedModuleSlug;
</script>

<template>
  <Modal :title="t('labels.hardpoint.selectModule')">
    <div class="row">
      <div
        v-for="mod in modules"
        :key="mod.id"
        class="col-12 col-md-6 module-item"
      >
        <Panel
          :alignment="PanelAlignmentsEnum.LEFT"
          slim
          class="module-panel"
          @click="selectModule(mod)"
        >
          <PanelImage
            :image="storeImage(mod)"
            image-size="auto"
            rounded="left"
            class="module-image"
            :alt="mod.name"
          />
          <div>
            <PanelHeading
              :level="HeadingLevelEnum.H3"
              title-align="right"
              multiline
            >
              {{ mod.name }}
            </PanelHeading>
            <div
              v-if="isSelected(mod)"
              v-tooltip="t('labels.selected')"
              class="module-panel-selected"
            >
              <i class="fa fa-check" />
            </div>
          </div>
        </Panel>
      </div>
    </div>
    <template #footer>
      <div class="float-sm-right">
        <Btn
          v-if="selectedModuleSlug"
          :size="BtnSizesEnum.SMALL"
          :inline="true"
          @click="clearModule"
        >
          {{ t("labels.hardpoint.clearModule") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
