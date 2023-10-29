<template>
  <Modal :title="t('headlines.newVehicles')">
    <form id="new-vehicles" class="new-vehicles" @submit.prevent="save">
      <div v-for="(item, index) in form.vehicles" :key="index" class="row">
        <div class="col-8 col-md-10">
          <TeaserPanel
            v-if="item.model"
            :item="item.model"
            variant="text"
            :with-description="false"
          />
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

      <CollectionFilterGroup
        name="model"
        :search-label="t('actions.findModel')"
        :collection="modelsCollection"
        value-attr="id"
        translation-key="newVehicle"
        :paginated="true"
        :searchable="true"
        :return-object="true"
        :no-label="true"
        @input="add"
      />
    </form>
    <template #footer>
      <div class="float-sm-right">
        <Btn
          type="submit"
          form="new-vehicles"
          :loading="submitting"
          size="large"
          :inline="true"
        >
          {{ t("actions.add") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import TeaserPanel from "@/shared/components/TeaserPanel/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { type Vehicle, type Model } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/frontend/composables/useI18n";
import { useQueryClient } from "@tanstack/vue-query";
import { useApiClient } from "@/frontend/composables/useApiClient";

type VehicleFormData = {
  vehicles: Partial<Vehicle>[];
};

type Props = {
  wanted?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  wanted: false,
});

const { t } = useI18n();

const submitting = ref(false);

const form = ref<VehicleFormData>({
  vehicles: [],
});

const add = (value: Model) => {
  form.value.vehicles.push({
    model: value,
  });
};

const removeItem = (index: number) => {
  form.value.vehicles.splice(index, 1);
};

onMounted(() => {
  form.value = {
    vehicles: [],
  };
});

const comlink = useComlink();

const { vehicles: vehiclesService } = useApiClient();

const queryClient = useQueryClient();

const save = async () => {
  submitting.value = true;

  form.value.vehicles.forEach(async (item) => {
    if (!item.model) {
      return;
    }

    try {
      await vehiclesService.vehicleCreate({
        requestBody: {
          wanted: props.wanted,
          modelId: item.model.id,
        },
      });
    } catch (error) {
      console.error(error);
    }
  });

  if (props.wanted) {
    queryClient.invalidateQueries({
      queryKey: ["wishlist"],
    });
  } else {
    queryClient.invalidateQueries({
      queryKey: ["hangar"],
    });
  }

  submitting.value = false;

  comlink.emit("close-modal");
};
</script>

<script lang="ts">
export default {
  name: "NewVehiclesModal",
};
</script>
