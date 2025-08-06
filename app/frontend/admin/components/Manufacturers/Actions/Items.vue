<script lang="ts">
export default {
  name: "ModelActions",
};
</script>

<script lang="ts" setup>
import { type Manufacturer } from "@/services/fyAdminApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  manufacturer: Manufacturer;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();

const sync = () => {
  console.info("sync", props.manufacturer);
};

const destroy = () => {
  console.info("destroy", props.manufacturer);
};
</script>

<template>
  <Btn :size="BtnSizesEnum.SMALL" @click="sync">
    <i class="fad fa-rotate" />
    <span v-if="withLabels">{{ t("actions.models.sync") }}</span>
  </Btn>
  <Btn
    :size="BtnSizesEnum.SMALL"
    :to="{
      name: 'admin-manufacturer-edit',
      params: { id: props.manufacturer.id },
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
