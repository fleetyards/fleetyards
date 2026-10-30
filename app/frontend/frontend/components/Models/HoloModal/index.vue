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
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import {
  type ModelStateEnum,
  useModelStates,
} from "@/frontend/composables/useModelStates";
import { useModelsStore } from "@/frontend/stores/models";
import { storeToRefs } from "pinia";
import { useModelHolo } from "@/frontend/composables/useModelHolo";
import { useHoloQuery } from "@/frontend/composables/useHoloQuery";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  model: Model;
  textured?: boolean;
  paintId?: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

// The ship page's own selection, so a pose picked here is the one it shows
// on the way back.
const modelsStore = useModelsStore();

const { modelState } = storeToRefs(modelsStore);

const { availableStates, holoStates, resolveState } = useModelStates(
  () => props.model,
);

const activeState = computed(() => resolveState(modelState.value));

const setModelState = (state: ModelStateEnum) => {
  modelsStore.setModelState(state);
};

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
  () => activeState.value,
  { textured: props.textured, paintId: props.paintId },
);

useHoloQuery(() => ({
  textured: texturedHoloAvailable.value && texturedHolo.value,
  paint: holoPaintId.value,
}));

// A textured holo that will not draw falls back to the plain one, and the
// address with it, so a copied link does not carry the failure on.
const holoUnavailable = () => {
  if (holoModel.value?.textured) texturedHolo.value = false;
};
</script>

<template>
  <HoloViewerModal
    :models="holoModel ? [holoModel] : []"
    @unavailable="holoUnavailable"
  >
    <template #groups>
      <BtnGroup
        v-if="holoStates.length > 1"
        segmented
        data-test="model-holo-modal-states"
      >
        <Btn
          v-for="holoState in availableStates"
          :key="holoState"
          :active="activeState === holoState"
          :data-test="`model-holo-modal-state-${holoState}`"
          @click="setModelState(holoState)"
        >
          {{ t(`labels.model.state.${holoState}`) }}
        </Btn>
      </BtnGroup>
    </template>
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
