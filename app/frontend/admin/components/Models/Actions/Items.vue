<template>
  <Btn :size="BtnSizesEnum.SMALL" @click="sync">
    <i class="fad fa-rotate" />
    <span v-if="withLabels">{{ t("actions.models.sync") }}</span>
  </Btn>
  <Btn :size="BtnSizesEnum.SMALL" @click="exchangeStoreImage">
    <i class="fad fa-arrow-right-arrow-left" />
    <span v-if="withLabels">{{ t("actions.models.exchangeStoreImage") }}</span>
  </Btn>
  <Btn
    :to="{ name: 'admin-model-images', params: { id: props.record.id } }"
    :size="BtnSizesEnum.SMALL"
  >
    <i class="fad fa-images" />
    <span v-if="withLabels">{{ t("actions.models.images") }}</span>
  </Btn>
  <Btn :size="BtnSizesEnum.SMALL" @click="edit">
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

<script lang="ts" setup generic="T extends ModelActionsRecord">
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { type ModelActionsRecord } from "@/admin/components/Models/Actions/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  record: T;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();

const sync = async () => {
  console.log("sync", props.record);
};

const exchangeStoreImage = () => {
  console.log("exchangeStoreImage", props.record);
};

const edit = () => {
  console.log("edit", props.record);
};

const destroy = () => {
  console.log("destroy", props.record);
};
</script>

<script lang="ts">
export default {
  name: "ModelActions",
};
</script>
