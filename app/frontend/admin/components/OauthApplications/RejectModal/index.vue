<script lang="ts">
export default {
  name: "OauthApplicationRejectModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import {
  type OauthApplication,
  useRejectOauthApplication,
  getOauthApplicationsQueryKey,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  oauthApplication: OauthApplication;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const queryClient = useQueryClient();

const rejectionReason = ref("");
const submitting = ref(false);
const error = ref<string | undefined>();

// The reason is what the owner is shown, so the button stays shut until there
// is one. The API refuses an empty reason too; this only saves the round trip.
const canSubmit = computed(
  () => rejectionReason.value.trim().length > 0 && !submitting.value,
);

const rejectMutation = useRejectOauthApplication();

const submit = async () => {
  if (!canSubmit.value) return;

  submitting.value = true;
  error.value = undefined;

  try {
    await rejectMutation.mutateAsync({
      id: props.oauthApplication.id,
      data: { rejectionReason: rejectionReason.value.trim() },
    });

    await queryClient.invalidateQueries({
      queryKey: getOauthApplicationsQueryKey(),
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
  <Modal
    :title="
      t('headlines.admin.oauthApplications.reject', {
        name: props.oauthApplication.name,
      })
    "
  >
    <p class="hint">
      <i class="fa-light fa-info-circle" />
      {{ t("texts.admin.oauthApplications.rejectHint") }}
    </p>

    <form id="oauth-application-reject" @submit.prevent="submit">
      <FormTextarea
        v-model="rejectionReason"
        name="rejectionReason"
        translation-key="oauthApplications.rejectionReason"
      />

      <p v-if="error" class="text-danger">{{ error }}</p>
    </form>

    <template #footer>
      <div class="modal-actions">
        <Btn
          :loading="submitting"
          :disabled="!canSubmit"
          :tone="BtnTonesEnum.DANGER"
          :size="BtnSizesEnum.LG"
          @click="submit"
        >
          {{ t("actions.oauthApplications.reject") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
