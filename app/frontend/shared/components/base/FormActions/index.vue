<script lang="ts">
export default {
  name: "FormActions",
};
</script>

<script lang="ts" setup>
import { BtnTypesEnum, BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  submitting?: boolean;
  formId?: string;
};

withDefaults(defineProps<Props>(), {
  submitting: false,
  formId: undefined,
});

const { t } = useI18n();

const emit = defineEmits(["cancel", "submit"]);
</script>

<template>
  <div class="form-actions">
    <hr />
    <div class="form-actions__inner">
      <Btn
        :type="BtnTypesEnum.BUTTON"
        data-test="submit-cancel"
        @click="emit('cancel')"
      >
        {{ t("actions.cancel") }}
      </Btn>
      <Btn
        :loading="submitting"
        :type="BtnTypesEnum.SUBMIT"
        data-test="submit-form"
        :size="BtnSizesEnum.LARGE"
        :form="formId"
      >
        {{ t("actions.save") }}
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
