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

const { displayConfirm } = useAppNotifications();

const handleCancel = () => {
  if (props.dirty) {
    displayConfirm({
      text: t("appModal.messages.confirm.dirty"),
      onConfirm: () => {
        emit("cancel");
      },
    });
  } else {
    emit("cancel");
  }
};
</script>

<template>
  <div class="form-actions">
    <hr />
    <div class="form-actions__inner">
      <Btn
        v-if="!hideCancel"
        :type="BtnTypesEnum.BUTTON"
        data-test="submit-cancel"
        @click="handleCancel"
      >
        {{ t("actions.cancel") }}
      </Btn>
      <Btn
        :loading="submitting"
        :type="BtnTypesEnum.SUBMIT"
        data-test="submit-form"
        :size="BtnSizesEnum.LARGE"
        :formId="formId"
      >
        {{ t("actions.save") }}
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
