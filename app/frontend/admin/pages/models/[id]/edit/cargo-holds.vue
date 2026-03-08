<script lang="ts">
export default {
  name: "AdminModelEditCargoHoldsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import {
  type ModelExtended,
  type ModelUpdateInput,
  type AdminCargoHold,
  type CargoHoldInput,
  useListCargoHolds as useListCargoHoldsQuery,
  useUpdateCargoHold as useUpdateCargoHoldMutation,
  getListCargoHoldsQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import ModelForm from "@/admin/components/Models/Form/index.vue";
import { useQueryClient } from "@tanstack/vue-query";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import {
  InputAlignmentsEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";
import { humanizeHoldName } from "@/shared/utils/CargoHolds";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();
const queryClient = useQueryClient();

// Cargo total form
const cargoInitialValues = ref<ModelUpdateInput>({
  cargo: props.model.metrics.cargo,
});

const cargoValidationSchema = {};

const { defineField } = useForm({
  initialValues: cargoInitialValues.value,
  validationSchema: cargoValidationSchema,
});

const [cargo, cargoProps] = defineField("cargo");

const editableList = ref<{
  editingId: string | null;
  creating: boolean;
  startCreate: () => void;
  finishEdit: () => void;
  finishCreate: () => void;
} | null>(null);

const queryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    modelIdEq: props.model.id,
  },
}));

const queryKey = computed(() => getListCargoHoldsQueryKey(queryParams.value));

const { perPage, page, updatePerPage } = usePagination(queryKey);

const { data, isLoading } = useListCargoHoldsQuery(queryParams);

const invalidateCargoHolds = async () => {
  await queryClient.invalidateQueries({
    queryKey: getListCargoHoldsQueryKey(),
  });
};

// Edit
const editForm = ref<CargoHoldInput>({});

const onStartEdit = (hold: AdminCargoHold) => {
  editForm.value = {
    offsetX: hold.offsetX ?? undefined,
    offsetY: hold.offsetY ?? undefined,
    offsetZ: hold.offsetZ ?? undefined,
    rotation: hold.rotation ?? undefined,
  };
};

const updateMutation = useUpdateCargoHoldMutation({
  mutation: {
    onSettled: invalidateCargoHolds,
  },
});

const onSaveEdit = async () => {
  const id = editableList.value?.editingId;
  if (!id) return;

  await updateMutation.mutateAsync({
    id,
    data: editForm.value,
  });

  editableList.value?.finishEdit();
};

const clearOffsets = async (hold: AdminCargoHold) => {
  await updateMutation.mutateAsync({
    id: hold.id,
    data: {
      offsetX: null,
      offsetY: null,
      offsetZ: null,
      rotation: null,
    },
  });
};

const hasOffset = (hold: AdminCargoHold) =>
  hold.offsetX != null ||
  hold.offsetY != null ||
  hold.offsetZ != null ||
  hold.rotation != null;

const formatDimensions = (hold: AdminCargoHold) =>
  `${hold.dimensionX} x ${hold.dimensionY} x ${hold.dimensionZ}m`;

const formatOffset = (hold: AdminCargoHold) => {
  if (!hasOffset(hold)) return "Auto";
  const parts = `${hold.offsetX ?? 0}, ${hold.offsetY ?? 0}, ${hold.offsetZ ?? 0}`;
  return hold.rotation != null ? `${parts} (r=${hold.rotation}°)` : parts;
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.models.edit.cargoHolds") }}</Heading>

  <ModelForm
    :model="model"
    :validation-schema="cargoValidationSchema"
    :initial-values="cargoInitialValues"
  >
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="cargo"
          v-bind="cargoProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="cargo"
          :type="InputTypesEnum.NUMBER"
          translation-key="model.cargo"
          :suffix="t('number.units.cargo')"
        />
      </div>
    </div>
    <FormTextarea
      v-if="model.cargoHolds"
      :model-value="JSON.stringify(model.cargoHolds, undefined, 4)"
      name="cargoHolds"
      translation-key="model.cargoHolds"
      class="base-data-output"
      disabled
    />
  </ModelForm>

  <hr />

  <InlineEditableList
    empty-name="Cargo Holds"
    :loading="isLoading"
    ref="editableList"
    :items="(data?.items as AdminCargoHold[]) || []"
    hide-destroy
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
  >
    <template #display="{ item }">
      <span style="display: flex; gap: 8px; align-items: center">
        <strong>{{
          item.name ? humanizeHoldName(item.name) : `Hold #${item.position}`
        }}</strong>
        <span class="text-muted">
          {{ formatDimensions(item) }} &middot; {{ item.capacityScu }} SCU
        </span>
      </span>
      <span :class="{ 'text-muted': !hasOffset(item) }">
        Offset: {{ formatOffset(item) }}
      </span>
    </template>

    <template #actions="{ item }">
      <Btn
        v-if="hasOffset(item)"
        v-tooltip="'Clear offsets'"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="clearOffsets(item)"
      >
        <i class="fad fa-undo" />
      </Btn>
    </template>

    <template #edit>
      <FormInput
        v-model="editForm.offsetX"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
        name="offsetX"
        translation-key="cargoHold.offsetX"
        :step="0.5"
      />
      <FormInput
        v-model="editForm.offsetY"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
        name="offsetY"
        translation-key="cargoHold.offsetY"
        :step="0.5"
      />
      <FormInput
        v-model="editForm.offsetZ"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
        name="offsetZ"
        translation-key="cargoHold.offsetZ"
        :step="0.5"
      />
      <FormInput
        v-model="editForm.rotation"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
        name="rotation"
        translation-key="cargoHold.rotation"
        :step="90"
      />
    </template>
  </InlineEditableList>

  <Paginator
    v-if="data"
    :query-result-ref="data"
    :per-page="perPage"
    :update-per-page="updatePerPage"
  />
</template>
