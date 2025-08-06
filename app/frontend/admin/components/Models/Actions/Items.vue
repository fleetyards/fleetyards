<script lang="ts">
export default {
  name: "ModelActions",
};
</script>

<script lang="ts" setup>
import { type Model } from "@/services/fyAdminApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  model: Model;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();

const sync = () => {
  console.info("sync", props.model);
};

const exchangeStoreImage = () => {
  console.info("exchangeStoreImage", props.model);
};

const destroy = () => {
  console.info("destroy", props.model);
};
</script>

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
    :to="{ name: 'admin-model-images', params: { id: props.model.id } }"
    :size="BtnSizesEnum.SMALL"
  >
    <i class="fad fa-images" />
    <span v-if="withLabels">{{ t("actions.models.images") }}</span>
  </Btn>
  <Btn
    :size="BtnSizesEnum.SMALL"
    :to="{ name: 'admin-model-edit', params: { id: props.model.id } }"
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
