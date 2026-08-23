<script lang="ts">
export default {
  name: "FormActions",
};
</script>

<script lang="ts" setup>
import { BtnTypesEnum, BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  formId: string;
  submitting?: boolean;
  dirty?: boolean;
  hideCancel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  submitting: false,
  dirty: false,
  hideCancel: false,
});

const { t } = useI18n();

const emit = defineEmits(["cancel"]);

const { displayConfirm, dismissConfirm } = useAppNotifications();

// The dialog is app-level and holds on to the callback it was given, so one left
// open outlives this component: confirming it later emits `cancel` at a parent
// that is no longer on screen, on whatever route the user moved to.
const awaitingConfirm = ref(false);

const handleCancel = () => {
  if (props.dirty) {
    awaitingConfirm.value = true;

    displayConfirm({
      text: t("appModal.messages.confirm.dirty"),
      onConfirm: () => {
        awaitingConfirm.value = false;
        emit("cancel");
      },
      onClose: () => {
        awaitingConfirm.value = false;
      },
    });
  } else {
    emit("cancel");
  }
};

onBeforeUnmount(() => {
  if (awaitingConfirm.value) {
    dismissConfirm();
  }
});
</script>

<template>
  <div class="form-actions">
    <hr />
    <div class="form-actions__inner">
      <Btn
        v-if="!hideCancel"
        :type="BtnTypesEnum.BUTTON"
        :size="BtnSizesEnum.LG"
        tone="danger"
        data-test="submit-cancel"
        @click="handleCancel"
      >
        {{ t("actions.cancel") }}
      </Btn>
      <Btn
        :loading="submitting"
        :type="BtnTypesEnum.SUBMIT"
        data-test="submit-form"
        :formId="formId"
        :size="BtnSizesEnum.LG"
      >
        {{ t("actions.save") }}
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
