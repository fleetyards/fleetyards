<script lang="ts">
export default {
  name: "VehiclePlaqueSupporterModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

const { t } = useI18n();
const comlink = useComlink();
</script>

<template>
  <Modal :title="t('headlines.vehiclePlaque.supporter')">
    <p>{{ t("texts.vehiclePlaque.supporter") }}</p>

    <template #footer>
      <Btn
        :to="{ name: 'support' }"
        data-test="vehicle-plaque-support"
        @click="comlink.emit('close-modal')"
      >
        {{ t("actions.supportUs") }}
      </Btn>
    </template>
  </Modal>
</template>
