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
import CoverPresetPicker from "@/shared/components/CoverPresetPicker/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useContractCover } from "@/frontend/composables/useContractCover";
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
const [deadline, deadlineProps] = defineField("deadline");
const [sourceFleetInventoryId, sourceProps] = defineField(
  "sourceFleetInventoryId",
);
const [destinationFleetInventoryId, destinationProps] = defineField(
  "destinationFleetInventoryId",
);
const [coverImagePreset] = defineField("coverImagePreset");
const [coverImage, coverImageProps] = defineField("coverImage");

const { presetsFor } = useContractCover();

// What this kind has art for. Changing the kind changes the offer, the way the
// event form follows its category.
const presetOptions = computed(() => presetsFor(kind.value as string));

const coverImageInput = ref<{ clear: () => void } | undefined>();

// Picking a preset drops an upload rather than sitting behind it: submit gives
// the upload precedence, so the two together would save the file and discard
// the preset the author just chose.
/*
 * `null` in the field means "detach what is saved", and it gets there two ways:
 * the author clearing the file themselves, and this handler clearing it so a
 * preset can take its place. Unpicking the tile withdraws the second and must
 * leave the first alone, which the value cannot say on its own.
 */
const detachedForPreset = ref(false);

/*
 * Anything the author does to the field is theirs, including clearing it. The
 * flag below only ever covers a detach this form asked for -- once the author
 * has cleared the file themselves, unpicking a tile must not put it back.
 *
 * Reachable because both actions write the same `null`: picking a preset over a
 * saved cover sets it, and a clear afterwards changes nothing visible, so
 * without this the form still thought the `null` was its own.
 */
const chooseTheUpload = (value: string | null | undefined) => {
  coverImage.value = value;
  detachedForPreset.value = false;
};

const chooseThePreset = (key: string | null) => {
  coverImagePreset.value = key;

  if (!key) {
    // Only while it is still the detach this handler asked for: an upload made
    // since would be thrown away by putting `undefined` back.
    if (detachedForPreset.value && coverImage.value === null) {
      coverImage.value = undefined;
    }

    detachedForPreset.value = false;

    return;
  }

  // A file uploaded here outranks the preset on submit, so it goes.
  if (coverImage.value) {
    coverImageInput.value?.clear();
    coverImage.value = undefined;
  }

  /*
   * So does a cover already saved -- `useContractCover` prefers an attachment
   * over any preset, so leaving it would make picking one look like it did
   * nothing. Remembered as ours, so unpicking can put it back.
   *
   * Only from `undefined`: a `null` already sitting there is the author's own
   * clear, which stands whatever happens to the tile.
   */
  if (coverImage.value === undefined && existingCoverImage.value) {
    coverImage.value = null;
    detachedForPreset.value = true;
  }
};

// The picker only offers the current kind's art, so a selection made before the
// kind changed is no longer on it. The model re-defaults a stale preset on save
// as well; this is so the form stops showing a choice it no longer offers.
watch(presetOptions, (options) => {
  if (!coverImagePreset.value) return;
  if (options.some((option) => option.key === coverImagePreset.value)) return;

  coverImagePreset.value = null;
});

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
    // An upload replaces the preset outright rather than sitting alongside one
    // that would win back if the file were later cleared.
    coverImagePreset: values.coverImage ? null : values.coverImagePreset,
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

        <div v-if="presetOptions.length" class="row">
          <div class="col-12">
            <CoverPresetPicker
              :model-value="coverImagePreset"
              @update:model-value="chooseThePreset"
              :presets="presetOptions"
              :label="t('labels.fleets.missions.coverPresets')"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-12">
            <FormFileInput
              ref="coverImageInput"
              :model-value="coverImage"
              v-bind="coverImageProps"
              @update:model-value="chooseTheUpload"
              :file="existingCoverImage as never"
              name="coverImage"
              :label="t('labels.fleets.missions.coverImage')"
              :allowed-types="AllowedFileTypes.IMAGE"
              clearable
            />
          </div>
        </div>
      </FormTab>

      <FormTab
        id="delivery"
        :label="t('labels.fleets.contracts.tabs.delivery')"
        :fields="['sourceFleetInventoryId', 'destinationFleetInventoryId']"
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
