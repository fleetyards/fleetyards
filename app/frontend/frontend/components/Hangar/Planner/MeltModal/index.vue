<script lang="ts">
export default {
  name: "HangarPlannerMeltModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import {
  type HangarPlanMelt,
  useCreateHangarPlanMelt,
  useHangarPlanResources,
  useUpdateHangarPlanMelt,
} from "@/services/fyApi";

type Props = {
  planId: string;
  melt?: HangarPlanMelt;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const comlink = useComlink();
const { updatePlan } = useHangarPlanCache();

const { data: resources } = useHangarPlanResources(() => props.planId);

const submitting = ref(false);
const vehicleId = ref<string | null>(props.melt?.vehicleId ?? null);
const valueOverride = ref<string>(props.melt?.valueOverride?.toString() ?? "");

const touched = ref(false);
watch([vehicleId, valueOverride], () => {
  touched.value = true;
});
useModalDirty(touched);

const vehicleOptions = computed(() =>
  (resources.value?.vehicles ?? [])
    .filter((vehicle) => !vehicle.usedBy)
    .map((vehicle) => ({
      value: vehicle.id,
      label: vehicle.name
        ? `${vehicle.name} (${vehicle.model.name})`
        : vehicle.model.name,
    })),
);

const createMutation = useCreateHangarPlanMelt();
const updateMutation = useUpdateHangarPlanMelt();

const onSubmit = async () => {
  submitting.value = true;

  const value = valueOverride.value === "" ? null : Number(valueOverride.value);

  try {
    const plan = props.melt
      ? await updateMutation.mutateAsync({
          hangarPlanId: props.planId,
          id: props.melt.id,
          data: { valueOverride: value },
        })
      : await createMutation.mutateAsync({
          hangarPlanId: props.planId,
          data: { vehicleId: vehicleId.value as string, valueOverride: value },
        });

    updatePlan(plan);
    comlink.emit("close-modal", true);
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Modal
    :title="melt ? t('hangarPlanner.editMelt') : t('hangarPlanner.addMelt')"
  >
    <form id="hangar-plan-melt-form" @submit.prevent="onSubmit">
      <BaseSelect
        v-if="!melt"
        v-model="vehicleId"
        name="vehicleId"
        :options="vehicleOptions"
        :label="t('hangarPlanner.fields.meltShip')"
      />
      <FormInput
        v-model="valueOverride"
        name="valueOverride"
        :type="InputTypesEnum.NUMBER"
        :min="0"
        :step="0.01"
        prefix="$"
        :label="t('hangarPlanner.fields.meltValue')"
        :info="t('hangarPlanner.fields.meltValueInfo')"
        no-placeholder
        standalone
      />
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="hangar-plan-melt-form"
        :loading="submitting"
        :disabled="!melt && !vehicleId"
        data-test="hangar-plan-melt-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
