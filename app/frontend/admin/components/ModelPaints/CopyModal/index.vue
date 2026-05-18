<script lang="ts">
export default {
  name: "ModelPaintCopyModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import ModelFilterGroup from "@/admin/components/base/ModelFilterGroup/index.vue";
import {
  type ModelPaint,
  type ModelPaintInput,
  useCreateModelPaint as useCreateModelPaintMutation,
  getListModelPaintsQueryKey,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  paints: ModelPaint[];
  sourceModelId: string;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const queryClient = useQueryClient();

const targetModelId = ref<string | undefined>();
const submitting = ref(false);
const error = ref<string | undefined>();

const title = computed(() =>
  props.paints.length > 1
    ? t("headlines.admin.modelPaints.bulkCopy", { count: props.paints.length })
    : t("headlines.admin.modelPaints.copy"),
);

const hint = computed(() =>
  props.paints.length > 1
    ? t("labels.modelPaint.bulkCopyHint", { count: props.paints.length })
    : t("labels.modelPaint.copyHint"),
);

const sameAsSource = computed(
  () => !!targetModelId.value && targetModelId.value === props.sourceModelId,
);

const canSubmit = computed(
  () => !!targetModelId.value && !sameAsSource.value && !submitting.value,
);

const createMutation = useCreateModelPaintMutation();

const buildPayload = (paint: ModelPaint): ModelPaintInput => ({
  name: paint.name,
  description: paint.description,
  modelId: targetModelId.value,
  active: paint.active,
  hidden: paint.hidden,
  onSale: paint.onSale,
  pledgePrice: paint.pledgePrice,
  productionStatus: paint.productionStatus,
  productionNote: paint.productionNote,
  storeImage: paint.media?.storeImage?.signedId,
});

const submit = async () => {
  if (!canSubmit.value) return;

  submitting.value = true;
  error.value = undefined;

  try {
    for (const paint of props.paints) {
      await createMutation.mutateAsync({ data: buildPayload(paint) });
    }

    await queryClient.invalidateQueries({
      queryKey: getListModelPaintsQueryKey(),
    });

    comlink.emit("close-modal");
  } catch (err) {
    error.value = err instanceof Error ? err.message : String(err);
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Modal :title="title">
    <p class="hint">
      <i class="fa-light fa-info-circle" />
      {{ hint }}
    </p>

    <form id="model-paint-copy" @submit.prevent="submit">
      <ModelFilterGroup
        v-model="targetModelId"
        :no-label="false"
        value-attr="id"
        :multiple="false"
        name="model"
      />

      <p v-if="sameAsSource" class="text-danger">
        {{ t("labels.modelPaint.copySameModel") }}
      </p>
      <p v-if="error" class="text-danger">{{ error }}</p>
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :disabled="!canSubmit"
          :size="BtnSizesEnum.LARGE"
          :inline="true"
          @click="submit"
        >
          {{ t("actions.copy") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
