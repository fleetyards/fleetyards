<script lang="ts">
export default {
  name: "FleetContractsForm",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FilterOption,
  type FleetContract,
  type FleetContractItemInput,
  type FleetContractDetail,
  FleetContractKindEnum,
  useFleetInventories,
  useCreateFleetContract,
  useUpdateFleetContract,
} from "@/services/fyApi";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  contract?: FleetContract | FleetContractDetail;
  // Goods written alongside a contract that does not exist yet. Sent with it,
  // so the two are saved in one transaction.
  items?: FleetContractItemInput[];
};

const props = defineProps<Props>();
const emit = defineEmits<{
  cancel: [];
  // The goods form outside this one needs to know: only a crafting contract
  // rules commodities out.
  "kind-change": [FleetContractKindEnum];
}>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const router = useRouter();

const isEdit = computed(() => !!props.contract);
const submitting = ref(false);

const fleetSlug = computed(() => props.fleet.slug);
const { data: inventories } = useFleetInventories(fleetSlug);

const inventoryOptions = computed<FilterOption[]>(() =>
  (inventories.value?.items ?? []).map((inventory) => ({
    value: inventory.id,
    label: inventory.location
      ? `${inventory.name} — ${inventory.location}`
      : inventory.name,
  })),
);

const kindOptions = computed<FilterOption[]>(() =>
  Object.values(FleetContractKindEnum).map((value) => ({
    value,
    label: t(`labels.fleets.contracts.kind.${value}`),
  })),
);

const { defineField, handleSubmit, meta, setErrors } = useForm({
  initialValues: {
    title: props.contract?.customTitle ?? "",
    description: props.contract?.description ?? "",
    kind: props.contract?.kind ?? FleetContractKindEnum.PROCUREMENT,
    reward: props.contract?.reward ?? "0",
    reimburseExpenses: props.contract?.reimburseExpenses ?? true,
    crewLimit: props.contract?.crewLimit ?? null,
    deadline: props.contract?.deadline ?? null,
    sourceFleetInventoryId: props.contract?.source?.id ?? null,
    destinationFleetInventoryId: props.contract?.destination?.id ?? null,
  },
});

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");
const [kind, kindProps] = defineField("kind");

watch(kind, (value) => emit("kind-change", value as FleetContractKindEnum), {
  immediate: true,
});
const [reward, rewardProps] = defineField("reward");
const [reimburseExpenses] = defineField("reimburseExpenses");
const [crewLimit, crewLimitProps] = defineField("crewLimit");
const [deadline, deadlineProps] = defineField("deadline");
const [sourceFleetInventoryId, sourceProps] = defineField(
  "sourceFleetInventoryId",
);
const [destinationFleetInventoryId, destinationProps] = defineField(
  "destinationFleetInventoryId",
);

// Only a transport contract collects from somewhere. The API refuses the other
// three combinations, so the field goes away rather than being sent as null and
// argued about.
const requiresSource = computed(
  () => kind.value === FleetContractKindEnum.TRANSPORT,
);

watch(requiresSource, (needed) => {
  if (!needed) sourceFleetInventoryId.value = null;
});

const createMutation = useCreateFleetContract();
const updateMutation = useUpdateFleetContract();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = {
    title: values.title || null,
    description: values.description || null,
    kind: values.kind as never,
    reward: String(values.reward ?? "0"),
    reimburseExpenses: values.reimburseExpenses,
    crewLimit: values.crewLimit ? Number(values.crewLimit) : null,
    // FormDateTime emits a local "YYYY-MM-DDTHH:MM" with no seconds and no
    // offset, which `format: date-time` rejects outright. Parsing it as local
    // and re-emitting ISO is the conversion, not a timezone shift.
    deadline: values.deadline ? new Date(values.deadline).toISOString() : null,
    sourceFleetInventoryId: requiresSource.value
      ? values.sourceFleetInventoryId
      : null,
    destinationFleetInventoryId: values.destinationFleetInventoryId as string,
  };

  const mutation = isEdit.value
    ? updateMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        slug: props.contract!.slug,
        data,
      })
    : createMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        data: { ...data, items: props.items },
      });

  await mutation
    .then((response) => {
      displaySuccess({
        text: isEdit.value
          ? t("messages.fleets.contract.update.success")
          : t("messages.fleets.contract.create.success"),
      });
      comlink.emit("fleet-contract-updated");

      const targetSlug = isEdit.value ? props.contract!.slug : response?.slug;
      if (targetSlug) {
        void router.push({
          // A new contract that arrived with its goods is ready to publish,
          // so it lands on its own page. One that did not goes to the form
          // that can still add them: `publish` refuses a contract with none,
          // and leaving that behind an Edit button hides the step.
          name:
            isEdit.value || props.items?.length
              ? "fleet-contract"
              : "fleet-contract-edit",
          params: { slug: props.fleet.slug, contract: targetSlug },
        });
      }
    })
    .catch((error) => {
      const { message, formErrors } = validationErrorFrom(error);

      setErrors(formErrors);

      displayAlert({
        text:
          message ||
          (isEdit.value
            ? t("messages.fleets.contract.update.failure")
            : t("messages.fleets.contract.create.failure")),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <form id="contract-form" class="contract-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12">
        <FormInput
          v-model="title"
          v-bind="titleProps"
          name="title"
          :label="t('labels.fleets.contracts.title')"
        >
          <template #subline>
            {{ t("labels.fleets.contracts.titleHint") }}
          </template>
        </FormInput>
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-6">
        <BaseSelect
          v-model="kind"
          v-bind="kindProps"
          :options="kindOptions"
          :label="t('labels.fleets.contracts.kind.label')"
          name="kind"
          :searchable="false"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="reward"
          v-bind="rewardProps"
          name="reward"
          :label="t('labels.fleets.contracts.reward')"
        />
      </div>
    </div>

    <div class="row">
      <div v-if="requiresSource" class="col-12 col-md-6">
        <BaseSelect
          v-model="sourceFleetInventoryId"
          v-bind="sourceProps"
          :options="inventoryOptions"
          :label="t('labels.fleets.contracts.from')"
          name="sourceFleetInventoryId"
        />
      </div>
      <div class="col-12 col-md-6">
        <BaseSelect
          v-model="destinationFleetInventoryId"
          v-bind="destinationProps"
          :options="inventoryOptions"
          :label="t('labels.fleets.contracts.to')"
          name="destinationFleetInventoryId"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-6">
        <FormDateTime
          v-model="deadline"
          v-bind="deadlineProps"
          name="deadline"
          :label="t('labels.fleets.contracts.deadline')"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="crewLimit"
          v-bind="crewLimitProps"
          name="crewLimit"
          type="number"
          :label="t('labels.fleets.contracts.crewLimit')"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12">
        <FormToggle
          v-model="reimburseExpenses"
          name="reimburseExpenses"
          :label="t('labels.fleets.contracts.reimburseExpenses')"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12">
        <FormTextarea
          v-model="description"
          v-bind="descriptionProps"
          name="description"
          :label="t('labels.fleets.contracts.description')"
        />
      </div>
    </div>

    <!-- Anything that belongs to the contract but is not one of its fields --
         the goods, on the edit page. Rendered here so the submit bar stays the
         last thing on the page rather than sitting above half of it. -->
    <slot name="sections" />

    <!-- FormActions renders the pair itself and takes no children; passing
         buttons in dropped them on the floor, and its own Cancel emitted at
         nobody. -->
    <FormActions
      form-id="contract-form"
      :submitting="submitting"
      :dirty="meta.dirty"
      @cancel="emit('cancel')"
    />
  </form>
</template>
