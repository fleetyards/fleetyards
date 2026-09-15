<script lang="ts">
export default {
  name: "DisplayOptionsModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  gridView: boolean;
  // The choice belongs to whichever store the list keeps it in - contracts,
  // events and missions each persist their own - so this only reports it.
  updateCallback: (gridView: boolean) => void;
  // Names the two buttons for the list that opened this, the way every other
  // per-page control here is named.
  testPrefix: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

// Tracked here as well as in the store that owns it: a modal is handed its
// props once, when it is opened, so reading the prop alone would leave both
// buttons highlighting whatever was chosen before this one was opened.
const active = ref(props.gridView);

const select = (next: boolean) => {
  active.value = next;
  props.updateCallback(next);
};
</script>

<template>
  <Modal :title="t('headlines.modals.models.displayOptions')">
    <div class="row">
      <div class="col-6">
        <Btn
          block
          :active="active"
          :size="BtnSizesEnum.LG"
          :data-test="`${testPrefix}-grid-view`"
          @click="select(true)"
        >
          <i class="fa-solid fa-th" />
          {{ t("actions.showGridView") }}
        </Btn>
      </div>
      <div class="col-6">
        <Btn
          block
          :active="!active"
          :size="BtnSizesEnum.LG"
          :data-test="`${testPrefix}-list-view`"
          @click="select(false)"
        >
          <i class="fa-duotone fa-list" />
          {{ t("actions.showTableView") }}
        </Btn>
      </div>
    </div>
  </Modal>
</template>
