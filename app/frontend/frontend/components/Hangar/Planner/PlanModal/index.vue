<script lang="ts">
export default {
  name: "HangarPlannerPlanModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import { useRouter } from "vue-router";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnTypesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import { firstErrorMessageFrom } from "@/shared/utils/ApiErrors";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import {
  type HangarPlan,
  HangarPlanSourceEnum,
  useCreateHangarPlan,
  useHangarPlans,
  useMe,
  useUpdateHangarPlan,
} from "@/services/fyApi";

type Props = {
  plan?: HangarPlan;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { money } = usePlanMoney();

// The current user rather than the plan: a new plan has none, and a sync run
// since the plan loaded is newer.
const { data: me } = useMe();

const syncedCredit = computed(() => {
  const credit = me.value?.rsiStoreCredit ?? props.plan?.syncedStoreCredit;

  return typeof credit === "number" ? credit : undefined;
});
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const router = useRouter();
const { updatePlan } = useHangarPlanCache();

const isEdit = computed(() => !!props.plan);
const submitting = ref(false);

const initialValues = {
  name: props.plan?.name ?? "",
  description: props.plan?.description ?? "",
  startingCredit: props.plan?.startingCredit ?? ("" as number | ""),
  buybackTokens: props.plan?.buybackTokens ?? ("" as number | ""),
  vatRate: props.plan?.vatRate ?? ("" as number | ""),
  source: HangarPlanSourceEnum.EMPTY as HangarPlanSourceEnum,
  sourcePlanId: null as string | null,
};

const { defineField, handleSubmit, values } = useForm({ initialValues });

useModalDirty(useFormDirty(values, initialValues));

const [name, nameProps] = defineField("name");
const [description, descriptionProps] = defineField("description");
const [startingCredit, startingCreditProps] = defineField("startingCredit");

const ownCredit = computed(
  () => startingCredit.value !== "" && startingCredit.value !== null,
);

const useSyncedCredit = () => {
  startingCredit.value = "";
};
const [buybackTokens, buybackTokensProps] = defineField("buybackTokens");
const [vatRate, vatRateProps] = defineField("vatRate");
const [source, sourceProps] = defineField("source");
const [sourcePlanId, sourcePlanIdProps] = defineField("sourcePlanId");

const sourceOptions = computed(() =>
  Object.values(HangarPlanSourceEnum).map((value) => ({
    value,
    label: t(`hangarPlanner.sources.${value}`),
  })),
);

const { data: plans } = useHangarPlans({
  query: { enabled: computed(() => !isEdit.value) },
});

const planOptions = computed(() =>
  (plans.value ?? []).map((plan) => ({ value: plan.id, label: plan.name })),
);

const createMutation = useCreateHangarPlan();
const updateMutation = useUpdateHangarPlan();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = {
    name: values.name,
    description: values.description || null,
    // Empty uses the credit the hangar sync read.
    startingCredit:
      values.startingCredit === "" || values.startingCredit === null
        ? null
        : Math.max(0, Number(values.startingCredit) || 0),
    buybackTokens:
      values.buybackTokens === "" || values.buybackTokens === null
        ? null
        : Math.max(0, Math.floor(Number(values.buybackTokens) || 0)),
    vatRate:
      values.vatRate === "" || values.vatRate === null
        ? null
        : Math.min(100, Math.max(0, Number(values.vatRate) || 0)),
  };

  try {
    if (props.plan) {
      updatePlan(await updateMutation.mutateAsync({ id: props.plan.id, data }));
    } else {
      const plan = await createMutation.mutateAsync({
        data: {
          ...data,
          source: values.source,
          sourcePlanId:
            values.source === HangarPlanSourceEnum.PLAN
              ? values.sourcePlanId
              : null,
        },
      });
      updatePlan(plan);
      await router.push({ name: "hangar-plan", params: { id: plan.id } });
    }

    displaySuccess({ text: t("hangarPlanner.messages.saved") });
    comlink.emit("close-modal", true);
  } catch (error) {
    displayAlert({
      text:
        firstErrorMessageFrom(error) ?? t("hangarPlanner.messages.saveFailed"),
    });
  } finally {
    submitting.value = false;
  }
});
</script>

<template>
  <Modal
    :title="
      isEdit ? t('hangarPlanner.editPlan') : t('hangarPlanner.createPlan')
    "
  >
    <form id="hangar-plan-form" @submit.prevent="onSubmit">
      <FormInput
        v-model="name"
        v-bind="nameProps"
        name="name"
        rules="required"
        :label="t('hangarPlanner.fields.name')"
        no-placeholder
      />
      <FormTextarea
        v-model="description"
        v-bind="descriptionProps"
        name="description"
        :label="t('hangarPlanner.fields.description')"
      />
      <FormInput
        v-model="startingCredit"
        v-bind="startingCreditProps"
        name="startingCredit"
        :type="InputTypesEnum.NUMBER"
        :min="0"
        :step="0.01"
        prefix="$"
        :label="t('hangarPlanner.fields.startingCredit')"
        :info="
          syncedCredit === undefined
            ? t('hangarPlanner.fields.startingCreditInfo')
            : t('hangarPlanner.fields.startingCreditSynced', {
                credit: money(syncedCredit),
              })
        "
        :placeholder="syncedCredit === undefined ? '0' : String(syncedCredit)"
      >
        <template v-if="syncedCredit !== undefined && ownCredit" #subline>
          <Btn
            :size="BtnSizesEnum.XS"
            :variant="BtnVariantsEnum.BARE"
            data-test="hangar-plan-use-synced-credit"
            @click="useSyncedCredit"
          >
            {{
              t("hangarPlanner.fields.useSyncedCredit", {
                credit: money(syncedCredit),
              })
            }}
          </Btn>
        </template>
      </FormInput>
      <FormInput
        v-model="buybackTokens"
        v-bind="buybackTokensProps"
        name="buybackTokens"
        :type="InputTypesEnum.NUMBER"
        :min="0"
        :step="1"
        :label="t('hangarPlanner.fields.buybackTokens')"
        :info="
          typeof plan?.syncedBuybackTokens === 'number'
            ? t('hangarPlanner.fields.buybackTokensSynced', {
                count: plan.syncedBuybackTokens,
              })
            : t('hangarPlanner.fields.buybackTokensInfo')
        "
        :placeholder="
          typeof plan?.syncedBuybackTokens === 'number'
            ? String(plan.syncedBuybackTokens)
            : '0'
        "
      />
      <FormInput
        v-model="vatRate"
        v-bind="vatRateProps"
        name="vatRate"
        :type="InputTypesEnum.NUMBER"
        :min="0"
        :max="100"
        :step="0.01"
        suffix="%"
        :label="t('hangarPlanner.fields.vatRate')"
        :info="t('hangarPlanner.fields.vatRateInfo')"
        no-placeholder
      />
      <template v-if="!isEdit">
        <BaseSelect
          v-model="source"
          v-bind="sourceProps"
          name="source"
          :options="sourceOptions"
          :label="t('hangarPlanner.fields.source')"
          :searchable="false"
          unsorted
        />
        <BaseSelect
          v-if="source === HangarPlanSourceEnum.PLAN"
          v-model="sourcePlanId"
          v-bind="sourcePlanIdProps"
          name="sourcePlanId"
          :options="planOptions"
          :label="t('hangarPlanner.fields.sourcePlan')"
        />
      </template>
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="hangar-plan-form"
        :loading="submitting"
        data-test="hangar-plan-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
