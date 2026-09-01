<script lang="ts">
export default {
  name: "NewVehiclesModal",
};
</script>

<script lang="ts" setup>
import PickerModal from "@/frontend/components/Models/PickerModal/index.vue";
import {
  ModelPickerBadge,
  type ModelPickerSelection,
} from "@/frontend/components/Models/PickerModal/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";

type Props = {
  wanted?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  wanted: false,
});

const { t } = useI18n();

const comlink = useComlink();

const { useCreateBulkMutation } = useVehicleMutations();

const mutation = useCreateBulkMutation();

const submitting = ref(false);

const title = computed(() =>
  props.wanted ? t("modelPicker.wishlistTitle") : t("modelPicker.hangarTitle"),
);

const submitLabel = computed(() =>
  props.wanted ? t("actions.addToWishlist") : t("actions.addToHangar"),
);

const highlight = computed(() =>
  props.wanted ? ModelPickerBadge.ON_WISHLIST : ModelPickerBadge.IN_HANGAR,
);

const save = async (selection: ModelPickerSelection[]) => {
  submitting.value = true;

  // One vehicle per copy: the endpoint takes a flat list, so a quantity of three
  // is the same model three times over.
  const vehicles = selection.flatMap(({ option, quantity }) =>
    Array.from({ length: quantity }, () => ({
      wanted: props.wanted,
      modelId: option.id,
    })),
  );

  await mutation
    .mutateAsync({ data: { vehicles } })
    .then(() => {
      comlink.emit("hangar-change");
    })
    .finally(() => {
      submitting.value = false;
      comlink.emit("close-modal");
    });
};
</script>

<template>
  <PickerModal
    :title="title"
    :submit-label="submitLabel"
    :submitting="submitting"
    :highlight="highlight"
    quantities
    @submit="save"
  />
</template>
