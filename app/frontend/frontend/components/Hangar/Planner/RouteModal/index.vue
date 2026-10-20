<script lang="ts">
export default {
  name: "HangarPlannerRouteModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnTypesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import ModelSelect from "@/frontend/components/Hangar/Planner/ModelSelect/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import {
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
  HangarPlanStartKindEnum,
  HangarPlanUpgradeSourceEnum,
  useCreateHangarPlanAcquisition,
  useHangarPlanResources,
  useUpdateHangarPlanAcquisition,
} from "@/services/fyApi";

type Props = {
  planId: string;
  candidate: HangarPlanCandidate;
  acquisition?: HangarPlanAcquisition;
};

type StepDraft = {
  key: number;
  sourceKind: HangarPlanUpgradeSourceEnum;
  toModelId: string | null;
  hangarPledgeItemId: string | null;
  buybackPledgeId: string | null;
  priceOverride: string;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { money } = usePlanMoney();
const { displayAlert } = useAppNotifications();
const comlink = useComlink();
const { updatePlan } = useHangarPlanCache();

const { data: resources } = useHangarPlanResources(() => props.planId);

const isEdit = computed(() => !!props.acquisition);
const submitting = ref(false);
const errorMessages = ref<string[]>([]);

let stepKey = 0;

const startKind = ref<HangarPlanStartKindEnum>(
  props.acquisition?.startKind ?? HangarPlanStartKindEnum.STORE,
);
const sourceVehicleId = ref<string | null>(
  props.acquisition?.sourceVehicleId ?? null,
);
const buybackPledgeId = ref<string | null>(
  props.acquisition?.buybackPledgeId ?? null,
);
const startModelId = ref<string | null>(
  props.acquisition?.startModel.id ?? props.candidate.model.id,
);
const priceOverride = ref<string>(
  props.acquisition?.priceOverride?.toString() ?? "",
);
const steps = ref<StepDraft[]>(
  (props.acquisition?.steps ?? []).map((step) => ({
    key: stepKey++,
    sourceKind: step.sourceKind,
    toModelId: step.toModel.id,
    hangarPledgeItemId: step.hangarPledgeItemId ?? null,
    buybackPledgeId: step.buybackPledgeId ?? null,
    priceOverride: step.priceOverride?.toString() ?? "",
  })),
);

const touched = ref(false);
watch(
  [
    startKind,
    sourceVehicleId,
    buybackPledgeId,
    startModelId,
    priceOverride,
    steps,
  ],
  () => {
    touched.value = true;
  },
  { deep: true },
);
useModalDirty(touched);

const startKindOptions = computed(() =>
  Object.values(HangarPlanStartKindEnum).map((value) => ({
    value,
    label: t(`hangarPlanner.startKinds.${value}`),
  })),
);

const stepKindOptions = computed(() =>
  Object.values(HangarPlanUpgradeSourceEnum).map((value) => ({
    value,
    label: t(`hangarPlanner.upgradeSources.${value}`),
  })),
);

const vehicleOptions = computed(() =>
  (resources.value?.vehicles ?? [])
    .filter(
      (vehicle) =>
        !vehicle.usedBy || vehicle.id === props.acquisition?.sourceVehicleId,
    )
    .map((vehicle) => ({
      value: vehicle.id,
      label: vehicle.name
        ? `${vehicle.name} (${vehicle.model.name})`
        : vehicle.model.name,
    })),
);

const shipBuybackOptions = computed(() =>
  (resources.value?.buybacks ?? [])
    .filter(
      (pledge) =>
        pledge.kind !== "upgrade" &&
        (!pledge.used || pledge.id === props.acquisition?.buybackPledgeId),
    )
    .map((pledge) => ({
      value: pledge.id,
      label: `${pledge.name} · ${money(pledge.price)}`,
    })),
);

const ownedSteps = computed(() =>
  (props.acquisition?.steps ?? []).map((step) => step.hangarPledgeItemId),
);

const upgradeOptions = computed(() =>
  (resources.value?.upgrades ?? [])
    .filter(
      (item) =>
        item.usedCount < item.quantity || ownedSteps.value.includes(item.id),
    )
    .map((item) => ({
      value: item.id,
      label: item.quantity > 1 ? `${item.name} (${item.quantity}×)` : item.name,
    })),
);

const upgradeBuybackOptions = computed(() =>
  (resources.value?.buybacks ?? [])
    .filter(
      (pledge) =>
        pledge.kind === "upgrade" &&
        (!pledge.used ||
          props.acquisition?.steps.some(
            (step) => step.buybackPledgeId === pledge.id,
          )),
    )
    .map((pledge) => ({
      value: pledge.id,
      label: `${pledge.name} · ${money(pledge.price)}`,
    })),
);

// Picking an upgrade the user holds fills in where it leads, when the RSI title
// names a ship we know.
const onUpgradePicked = (step: StepDraft) => {
  const sources = [
    ...(resources.value?.upgrades ?? []).map((item) => ({
      id: item.id,
      toId: item.toModel?.id,
    })),
    ...(resources.value?.buybacks ?? []).map((pledge) => ({
      id: pledge.id,
      toId: pledge.upgradeToModel?.id,
    })),
  ];
  const picked = sources.find(
    (source) =>
      source.id === step.hangarPledgeItemId ||
      source.id === step.buybackPledgeId,
  );

  if (picked?.toId) step.toModelId = picked.toId;
};

const addStep = () => {
  steps.value.push({
    key: stepKey++,
    sourceKind: HangarPlanUpgradeSourceEnum.STORE,
    toModelId: steps.value.length ? null : props.candidate.model.id,
    hangarPledgeItemId: null,
    buybackPledgeId: null,
    priceOverride: "",
  });
};

const removeStep = (key: number) => {
  steps.value = steps.value.filter((step) => step.key !== key);
};

const endsOnCandidate = computed(() => {
  const last = steps.value[steps.value.length - 1];
  if (last) return last.toModelId === props.candidate.model.id;
  if (startKind.value === HangarPlanStartKindEnum.OWNED) {
    const vehicle = resources.value?.vehicles.find(
      (entry) => entry.id === sourceVehicleId.value,
    );
    return !vehicle || vehicle.model.id === props.candidate.model.id;
  }
  return startModelId.value === props.candidate.model.id;
});

const toPrice = (value: string) => (value === "" ? null : Number(value));

const stepInputs = () =>
  steps.value.map((step) => ({
    sourceKind: step.sourceKind,
    toModelId: step.toModelId as string,
    hangarPledgeItemId:
      step.sourceKind === HangarPlanUpgradeSourceEnum.OWNED_CCU
        ? step.hangarPledgeItemId
        : null,
    buybackPledgeId:
      step.sourceKind === HangarPlanUpgradeSourceEnum.BUYBACK
        ? step.buybackPledgeId
        : null,
    priceOverride: toPrice(step.priceOverride),
  }));

const createMutation = useCreateHangarPlanAcquisition();
const updateMutation = useUpdateHangarPlanAcquisition();

const onSubmit = async () => {
  submitting.value = true;
  errorMessages.value = [];

  try {
    const plan = props.acquisition
      ? await updateMutation.mutateAsync({
          hangarPlanId: props.planId,
          id: props.acquisition.id,
          data: {
            priceOverride: toPrice(priceOverride.value),
            steps: stepInputs(),
          },
        })
      : await createMutation.mutateAsync({
          hangarPlanId: props.planId,
          data: {
            candidateId: props.candidate.id,
            startKind: startKind.value,
            sourceVehicleId:
              startKind.value === HangarPlanStartKindEnum.OWNED
                ? sourceVehicleId.value
                : null,
            buybackPledgeId:
              startKind.value === HangarPlanStartKindEnum.BUYBACK
                ? buybackPledgeId.value
                : null,
            startModelId:
              startKind.value === HangarPlanStartKindEnum.OWNED
                ? null
                : startModelId.value,
            priceOverride: toPrice(priceOverride.value),
            steps: stepInputs(),
          },
        });

    updatePlan(plan);
    comlink.emit("close-modal", true);
  } catch (error) {
    const response = (
      error as {
        response?: {
          data?: { errors?: { messages?: { message?: string }[] }[] };
        };
      }
    ).response;
    errorMessages.value = (response?.data?.errors ?? [])
      .flatMap((entry) => entry.messages ?? [])
      .map((entry) => entry.message)
      .filter((message): message is string => !!message);
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Modal
    :title="
      t(isEdit ? 'hangarPlanner.editRoute' : 'hangarPlanner.addRoute', {
        ship: candidate.model.name,
      })
    "
  >
    <form id="hangar-plan-route-form" @submit.prevent="onSubmit">
      <BaseSelect
        v-model="startKind"
        name="startKind"
        :options="startKindOptions"
        :label="t('hangarPlanner.fields.startKind')"
        :searchable="false"
        :disabled="isEdit"
        unsorted
      />

      <BaseSelect
        v-if="startKind === HangarPlanStartKindEnum.OWNED"
        v-model="sourceVehicleId"
        name="sourceVehicleId"
        :options="vehicleOptions"
        :label="t('hangarPlanner.fields.ownedShip')"
        :disabled="isEdit"
      />
      <BaseSelect
        v-if="startKind === HangarPlanStartKindEnum.BUYBACK"
        v-model="buybackPledgeId"
        name="buybackPledgeId"
        :options="shipBuybackOptions"
        :label="t('hangarPlanner.fields.buyback')"
        :disabled="isEdit"
      />
      <ModelSelect
        v-if="startKind !== HangarPlanStartKindEnum.OWNED && !isEdit"
        v-model="startModelId"
        name="startModelId"
        :label="t('hangarPlanner.fields.startModel')"
      />

      <FormInput
        v-if="
          startKind === HangarPlanStartKindEnum.STORE ||
          startKind === HangarPlanStartKindEnum.BUYBACK
        "
        v-model="priceOverride"
        name="priceOverride"
        :type="InputTypesEnum.NUMBER"
        :min="0"
        :step="0.01"
        prefix="$"
        :label="t('hangarPlanner.fields.priceOverride')"
        :info="t('hangarPlanner.fields.priceOverrideInfo')"
        no-placeholder
        standalone
      />

      <fieldset class="route-steps">
        <legend>{{ t("hangarPlanner.upgradeSteps") }}</legend>
        <div
          v-for="(step, index) in steps"
          :key="step.key"
          class="route-step"
          data-test="hangar-plan-route-step"
        >
          <div class="route-step-head">
            <span>{{
              t("hangarPlanner.stepNumber", { number: index + 1 })
            }}</span>
            <Btn
              :size="BtnSizesEnum.XS"
              :variant="BtnVariantsEnum.BARE"
              :tone="BtnTonesEnum.DANGER"
              :aria-label="t('hangarPlanner.removeStep')"
              @click="removeStep(step.key)"
            >
              <i class="fa-light fa-trash" />
            </Btn>
          </div>
          <BaseSelect
            v-model="step.sourceKind"
            :name="`steps.${index}.sourceKind`"
            :options="stepKindOptions"
            :label="t('hangarPlanner.fields.upgradeSource')"
            :searchable="false"
            unsorted
          />
          <BaseSelect
            v-if="step.sourceKind === HangarPlanUpgradeSourceEnum.OWNED_CCU"
            v-model="step.hangarPledgeItemId"
            :name="`steps.${index}.hangarPledgeItemId`"
            :options="upgradeOptions"
            :label="t('hangarPlanner.fields.ownedUpgrade')"
            @update:model-value="onUpgradePicked(step)"
          />
          <BaseSelect
            v-if="step.sourceKind === HangarPlanUpgradeSourceEnum.BUYBACK"
            v-model="step.buybackPledgeId"
            :name="`steps.${index}.buybackPledgeId`"
            :options="upgradeBuybackOptions"
            :label="t('hangarPlanner.fields.buyback')"
            @update:model-value="onUpgradePicked(step)"
          />
          <ModelSelect
            v-model="step.toModelId"
            :name="`steps.${index}.toModelId`"
            :label="t('hangarPlanner.fields.upgradeTo')"
          />
          <FormInput
            v-if="step.sourceKind !== HangarPlanUpgradeSourceEnum.OWNED_CCU"
            v-model="step.priceOverride"
            :name="`steps.${index}.priceOverride`"
            :type="InputTypesEnum.NUMBER"
            :min="0"
            :step="0.01"
            prefix="$"
            :label="t('hangarPlanner.fields.priceOverride')"
            no-placeholder
            standalone
          />
        </div>
        <Btn
          :size="BtnSizesEnum.SM"
          data-test="hangar-plan-route-add-step"
          @click="addStep"
        >
          <i class="fa-light fa-plus" />
          {{ t("hangarPlanner.addStep") }}
        </Btn>
      </fieldset>

      <Alert v-if="!endsOnCandidate" variant="warning">
        {{ t("hangarPlanner.routeMustEnd", { ship: candidate.model.name }) }}
      </Alert>
      <Alert v-if="errorMessages.length" variant="danger">
        <ul class="route-errors">
          <li v-for="message in errorMessages" :key="message">
            {{ message }}
          </li>
        </ul>
      </Alert>
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="hangar-plan-route-form"
        :loading="submitting"
        :disabled="!endsOnCandidate"
        data-test="hangar-plan-route-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.route-steps {
  margin: 16px 0;
  padding: 0;
  border: 0;

  legend {
    margin-bottom: 8px;
    font-weight: 600;
  }
}

.route-step {
  margin-bottom: 12px;
  padding: 12px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 6px;
}

.route-step-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
  color: var(--color-text-dim);
}

.route-errors {
  margin: 0;
  padding-left: 16px;
}
</style>
