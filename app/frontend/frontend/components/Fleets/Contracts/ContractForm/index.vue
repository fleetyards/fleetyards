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
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormTabs from "@/shared/components/base/FormTabs/index.vue";
import FormTab from "@/shared/components/base/FormTabs/Tab/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import SquadronSelect from "@/frontend/components/Fleets/Squadrons/SquadronSelect/index.vue";
import { useSquadronVisibility } from "@/frontend/composables/useSquadronVisibility";
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
  type FleetContractDestination,
  type FleetContractEndpoint,
  FleetContractDestinationHolderEnum,
  FleetContractKindEnum,
  useFleetContractDestinations,
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

// Where the goods can go, as the API answers it for this reader: the fleet
// inventories they could accept deliveries into, and their own. Deciding that
// here would mean re-deriving the privilege and visibility rules the API
// checks the choice against anyway.
//
// Editing, the API is told which contract: its hangar half belongs to the
// author, so anybody else is offered none of their own.
const { data: destinations } = useFleetContractDestinations(
  fleetSlug,
  computed(() => (props.contract ? { contractSlug: props.contract.slug } : {})),
);

// One picker over two id fields, so the value carries which one it is.
const destinationKey = (destination: { holder: string; id: string }) =>
  `${destination.holder}:${destination.id}`;

const destinationLabel = (
  destination: FleetContractDestination | NonNullable<FleetContractEndpoint>,
  offered: boolean,
) => {
  if (destination.holder === FleetContractDestinationHolderEnum.FLEET) {
    return destination.location
      ? `${destination.name} — ${destination.location}`
      : destination.name;
  }

  // Only the author is offered their own inventories. Anybody else editing
  // the contract still sees the one it delivers into, named as the author's.
  return offered
    ? t("labels.fleets.contracts.myHangarInventory", {
        name: destination.name,
      })
    : t("labels.fleets.contracts.authorHangarInventory", {
        name: destination.name,
        username: props.contract?.createdBy?.username ?? "",
      });
};

const destinationOptions = computed<FilterOption[]>(() => {
  const offered = destinations.value ?? [];
  const current = props.contract?.destination;
  const options = offered.map((destination) => ({
    value: destinationKey(destination),
    label: destinationLabel(destination, true),
  }));

  if (
    current &&
    !offered.some((destination) => destination.id === current.id)
  ) {
    options.push({
      value: destinationKey(current),
      label: destinationLabel(current, false),
    });
  }

  return options;
});

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
    visibility: props.contract?.visibility ?? "members_only",
    fleetSquadronIds: (props.contract?.fleetSquadrons ?? []).map(
      (squadron) => squadron.id,
    ),
    deadline: props.contract?.deadline ?? null,
    sourceFleetInventoryId: props.contract?.source?.id ?? null,
    destination: props.contract?.destination
      ? destinationKey(props.contract.destination)
      : null,
    coverImagePreset: props.contract?.coverImagePreset ?? null,
    coverImage: undefined as string | null | undefined,
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
const [visibility, visibilityProps] = defineField("visibility");
const [fleetSquadronIds] = defineField("fleetSquadronIds");

const { withSquadronChoice } = useSquadronVisibility(
  () => props.fleet,
  "squadron_only",
  visibility,
);

const visibilityOptions = computed<FilterOption[]>(() =>
  withSquadronChoice(
    ["members_only", "squadron_only"].map((value) => ({
      value,
      label: t(`labels.fleets.contracts.visibilities.${value}`),
    })),
  ),
);

// The squadron list is the other half of the squadron visibility, so it is
// only asked for when that is what is chosen.
const restrictedToSquadrons = computed(
  () => visibility.value === "squadron_only",
);
const [deadline, deadlineProps] = defineField("deadline");
const [sourceFleetInventoryId, sourceProps] = defineField(
  "sourceFleetInventoryId",
);
const [destination, destinationProps] = defineField("destination");
const [coverImagePreset] = defineField("coverImagePreset");
const [coverImage, coverImageProps] = defineField("coverImage");

const existingCoverImage = computed(() => props.contract?.coverImage);

// Only a transport contract collects from somewhere. The API refuses the other
// three combinations, so the field goes away rather than being sent as null and
// argued about.
const requiresSource = computed(
  () => kind.value === FleetContractKindEnum.TRANSPORT,
);

watch(requiresSource, (needed) => {
  if (!needed) sourceFleetInventoryId.value = null;
});

const deliversToHangar = computed(
  () =>
    destinationIds(destination.value as string | null)
      .destinationInventoryId !== null,
);

const destinationIds = (value: string | null | undefined) => {
  const [holder, id] = (value ?? "").split(":");

  return {
    destinationFleetInventoryId:
      holder === FleetContractDestinationHolderEnum.FLEET ? id : null,
    destinationInventoryId:
      holder === FleetContractDestinationHolderEnum.USER ? id : null,
  };
};

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
    visibility: values.visibility as "members_only" | "squadron_only",
    // Cleared when the visibility is not the squadron one, so switching away
    // does not leave a restriction the form no longer shows.
    fleetSquadronIds: restrictedToSquadrons.value
      ? (values.fleetSquadronIds ?? [])
      : [],
    // FormDateTime emits a local "YYYY-MM-DDTHH:MM" with no seconds and no
    // offset, which `format: date-time` rejects outright. Parsing it as local
    // and re-emitting ISO is the conversion, not a timezone shift.
    deadline: values.deadline ? new Date(values.deadline).toISOString() : null,
    sourceFleetInventoryId: requiresSource.value
      ? values.sourceFleetInventoryId
      : null,
    // Both keys, one of them null: the contract has a single destination and
    // naming one kind is what clears the other.
    ...destinationIds(values.destination),
    // The field keeps the two exclusive itself -- an upload retires the preset,
    // a preset clears the upload -- so this is passed on as it stands.
    coverImagePreset: values.coverImagePreset,
    // Passed through rather than coerced, because all three values mean
    // something different: `undefined` drops the key and keeps what is
    // attached, `null` is how the field says it was cleared, and a signed id
    // is a replacement. `|| undefined` would turn a clear back into a keep.
    coverImage: values.coverImage,
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
      const { message, formErrors } = validationErrorFrom(error, {
        destinationFleetInventory: "destination",
        destinationInventory: "destination",
      });

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
    <FormTabs>
      <FormTab
        id="details"
        :label="t('labels.fleets.contracts.tabs.details')"
        :fields="['title', 'kind']"
      >
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

        <div class="row">
          <div class="col-12">
            <!-- The picker opens on the kind this form is editing, and every
                 other kind's art is one chip away. -->
            <FormFileInput
              v-model="coverImage"
              v-model:preset-value="coverImagePreset"
              v-bind="coverImageProps"
              :file="existingCoverImage as never"
              name="coverImage"
              :label="t('labels.fleets.missions.coverImage')"
              :allowed-types="AllowedFileTypes.IMAGE"
              preset-catalogue="contracts"
              :preset-group="kind as string"
              clearable
            />
          </div>
        </div>
      </FormTab>

      <FormTab
        id="delivery"
        :label="t('labels.fleets.contracts.tabs.delivery')"
        :fields="['sourceFleetInventoryId', 'destination']"
      >
        <div class="row">
          <!-- Only a transport contract collects from somewhere; the API
               refuses the other three combinations, so the field goes away
               rather than being sent as null and argued about. -->
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
              v-model="destination"
              v-bind="destinationProps"
              :options="destinationOptions"
              :label="t('labels.fleets.contracts.to')"
              name="destination"
              data-test="contract-destination"
            />
            <p
              v-if="deliversToHangar"
              class="contract-destination-hint"
              data-test="contract-destination-hint"
            >
              {{ t("labels.fleets.contracts.toHint") }}
            </p>
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
        </div>
      </FormTab>

      <FormTab
        id="crew"
        :label="t('labels.fleets.contracts.tabs.crew')"
        :fields="['reward', 'crewLimit']"
      >
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="reward"
              v-bind="rewardProps"
              name="reward"
              :label="t('labels.fleets.contracts.reward')"
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

        <!-- Who the work is for. On the crew tab because that is where the
             question of who takes it already lives. -->
        <div class="row">
          <div class="col-12 col-md-6">
            <BaseSelect
              v-model="visibility"
              v-bind="visibilityProps"
              :options="visibilityOptions"
              :label="t('labels.fleets.contracts.visibility')"
              name="visibility"
              :searchable="false"
            />
          </div>
          <div v-if="restrictedToSquadrons" class="col-12 col-md-6">
            <SquadronSelect v-model="fleetSquadronIds" :fleet="props.fleet" />
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
      </FormTab>

      <!-- The goods, handed in from outside: drafts on the create page, the
           saved lines on the edit page. The tab names the section, so the
           pages no longer bring a heading of their own. -->
      <FormTab
        v-if="$slots.sections"
        id="goods"
        :label="t('labels.fleets.contracts.tabs.goods')"
      >
        <slot name="sections" />
      </FormTab>

      <FormActions
        form-id="contract-form"
        :submitting="submitting"
        :dirty="meta.dirty"
        @cancel="emit('cancel')"
      />
    </FormTabs>
  </form>
</template>

<style lang="scss" scoped>
.contract-destination-hint {
  margin-top: -0.5rem;
  color: var(--color-text-dim);
  font-size: 0.875rem;
}
</style>
