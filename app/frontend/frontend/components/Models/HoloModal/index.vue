<script lang="ts">
export default {
  name: "ModelHoloModal",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import HoloViewerModal from "@/shared/components/HoloViewer/Modal/index.vue";
import { type Model } from "@/services/fyApi";
import { type ModelStateEnum } from "@/frontend/composables/useModelStates";
import { useModelHolo } from "@/frontend/composables/useModelHolo";
import { useHoloQuery } from "@/frontend/composables/useHoloQuery";
import { useI18n } from "@/shared/composables/useI18n";
import { type RouterLinkProps } from "vue-router";

type Props = {
  model: Model;
  state: ModelStateEnum;
  textured?: boolean;
  paintId?: string;
  backRoute: RouterLinkProps["to"];
};

const props = defineProps<Props>();

const { t } = useI18n();

const {
  texturedHolo,
  texturedHoloAvailable,
  toggleTexturedHolo,
  holoPaints,
  holoPaintId,
  holoPaint,
  holoModel,
} = useModelHolo(
  () => props.model,
  () => props.state,
  { textured: props.textured, paintId: props.paintId },
);

useHoloQuery(() => ({
  textured: texturedHoloAvailable.value && texturedHolo.value,
  paint: holoPaintId.value,
}));
</script>

<template>
  <HoloViewerModal
    :models="holoModel ? [holoModel] : []"
    :back-route="backRoute"
  >
    <template #controls>
      <Btn
        v-if="texturedHoloAvailable"
        :active="texturedHolo"
        v-tooltip="t('labels.texturedHolo')"
        :aria-label="t('labels.texturedHolo')"
        data-test="model-holo-modal-textured"
        @click="toggleTexturedHolo"
      >
        <i class="fa-duotone fa-palette" />
      </Btn>
      <BtnDropdown
        v-if="texturedHoloAvailable && texturedHolo && holoPaints.length"
        expand-bottom
        expand-left
        data-test="model-holo-modal-paint"
      >
        <template #label>
          <span>{{ holoPaint?.name ?? t("labels.texturedHoloOwnPaint") }}</span>
          <i class="fa-light fa-chevron-down" />
        </template>
        <Btn :active="!holoPaint" @click="holoPaintId = undefined">
          {{ t("labels.texturedHoloOwnPaint") }}
        </Btn>
        <Btn
          v-for="paint in holoPaints"
          :key="paint.id"
          :active="holoPaint?.id === paint.id"
          @click="holoPaintId = paint.id"
        >
          {{ paint.name }}
        </Btn>
      </BtnDropdown>
    </template>
  </HoloViewerModal>
</template>
