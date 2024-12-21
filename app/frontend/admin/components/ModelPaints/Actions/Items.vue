<template>
  <Btn
    :size="BtnSizesEnum.SMALL"
    :to="{
      name: 'admin-model-paint-edit',
      params: { id: props.modelPaint.id },
    }"
  >
    <i class="fad fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    :size="BtnSizesEnum.SMALL"
    :variant="BtnVariantsEnum.DANGER"
    @click="destroy"
  >
    <i class="fad fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>

<script lang="ts" setup>
import { type ModelPaint } from "@/services/fyAdminApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  modelPaint: ModelPaint;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();

const destroy = () => {
  console.log("destroy", props.modelPaint);
};
</script>

<script lang="ts">
export default {
  name: "ModelActions",
};
</script>
