<script lang="ts">
export default {
  name: "NewVehiclesModal",
};
</script>

<script lang="ts" setup>
import ModelFilterGroup from "@/frontend/components/base/ModelFilterGroup/index.vue";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import TeaserPanel from "@/shared/components/TeaserPanel/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { type Model } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { BtnSizesEnum, BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { type FilterGroupOption } from "@/shared/components/base/FilterGroup/index.vue";

type Props = {
  wanted?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  wanted: false,
});

const { t } = useI18n();

const submitting = ref(false);

const removeItem = (index: number) => {
  models.value.splice(index, 1);
};

const newModel = ref<FilterGroupOption<Model>>();

const comlink = useComlink();

const { useCreateBulkMutation } = useVehicleMutations();

const mutation = useCreateBulkMutation();

const models = ref<Model[]>([]);

watch(
  () => newModel.value,
  (value) => {
    if (!value) {
      return;
    }

    add();
  },
);

const add = async () => {
  if (!newModel.value) {
    return;
  }

  const existingModel = models.value.find(
    (model) => model.slug === newModel.value?.value,
  );

  if (!existingModel) {
    models.value.push(newModel.value.object);
  }

  newModel.value = undefined;
};

const newVehicles = computed(() => {
  return models.value.map((model) => {
    return {
      wanted: props.wanted,
      modelId: model.id,
    };
  });
});

const save = async () => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      data: {
        vehicles: newVehicles.value,
      },
    })
    .finally(() => {
      submitting.value = false;
      comlink.emit("close-modal");
    });
};
</script>

<template>
  <Modal :title="t('headlines.newVehicles')">
    <form id="new-vehicles" class="new-vehicles" @submit.prevent="save">
      <div v-for="(model, index) in models" :key="index" class="row">
        <div class="col-8 col-md-10">
          <TeaserPanel :item="model" :with-description="false" slim />
        </div>
        <div class="col-4 col-md-2">
          <Btn
            v-tooltip="t('actions.remove')"
            :aria-label="t('actions.remove')"
            @click="removeItem(index)"
          >
            <i class="fa fa-trash" />
          </Btn>
        </div>
      </div>

      {{ newModel }}
      <ModelFilterGroup v-model="newModel" return-object name="new-model" />
    </form>
    <template #footer>
      <div class="float-sm-right">
        <Btn
          :type="BtnTypesEnum.SUBMIT"
          form="new-vehicles"
          :loading="submitting"
          :size="BtnSizesEnum.LARGE"
          :inline="true"
        >
          {{ t("actions.add") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
