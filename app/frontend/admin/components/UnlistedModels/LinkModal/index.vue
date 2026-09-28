<script lang="ts">
export default {
  name: "UnlistedModelLinkModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import ModelSelect from "@/admin/components/base/ModelSelect/index.vue";
import {
  type ScDataUnlistedModel,
  useScDataUnlistedModelLink,
  getScDataUnlistedModelsQueryKey,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  unlistedModel: ScDataUnlistedModel;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const queryClient = useQueryClient();

// Prefilled with what the export lets us work out — the ship of that name, else
// the one this extends. Both are suggestions; the export never says enough to be
// sure, so the admin confirms.
const modelId = ref<string | undefined>(
  props.unlistedModel.existingModel?.id ?? props.unlistedModel.baseModel?.id,
);
const submitting = ref(false);
const error = ref<string | undefined>();

const linkMutation = useScDataUnlistedModelLink();

const submit = async () => {
  if (!modelId.value || submitting.value) return;

  submitting.value = true;
  error.value = undefined;

  try {
    await linkMutation.mutateAsync({
      id: props.unlistedModel.id,
      data: { modelId: modelId.value },
    });

    await queryClient.invalidateQueries({
      queryKey: getScDataUnlistedModelsQueryKey(),
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
  <Modal :title="t('headlines.admin.unlistedModels.link')">
    <p class="hint">
      <i class="fa-light fa-info-circle" />
      {{
        t("labels.unlistedModel.linkHint", {
          identifier: props.unlistedModel.identifier,
        })
      }}
    </p>

    <form id="unlisted-model-link" @submit.prevent="submit">
      <ModelSelect
        v-model="modelId"
        :no-label="false"
        value-attr="id"
        :multiple="false"
        name="model"
      />

      <p v-if="error" class="text-danger">{{ error }}</p>
    </form>

    <template #footer>
      <div class="modal-actions">
        <Btn
          :loading="submitting"
          :disabled="!modelId || submitting"
          :size="BtnSizesEnum.LG"
          @click="submit"
        >
          {{ t("actions.unlistedModel.link") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
