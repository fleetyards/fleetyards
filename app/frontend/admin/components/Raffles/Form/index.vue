<script lang="ts">
export default {
  name: "RaffleForm",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import { type Raffle, type RaffleInput } from "@/services/fyAdminApi";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import ModelSelect from "@/admin/components/base/ModelSelect/index.vue";
import RaffleGallery from "@/admin/components/Raffles/Gallery/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  formId: string;
  raffle?: Raffle;
  submitting?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  raffle: undefined,
  submitting: false,
});

const emit = defineEmits<{
  submit: [payload: RaffleInput];
  cancel: [];
}>();

const { t } = useI18n();

const { displayAlert } = useAppNotifications();

const drawn = computed(() => !!props.raffle?.drawnAt);

type FormValues = {
  title: string;
  description?: string;
  modelId?: string;
  // Never filled from the server: the API only says whether a code is set.
  code?: string;
  startsAt: string | null;
  runDays: number;
  claimPeriodDays: number;
  published: boolean;
};

const { defineField, handleSubmit, meta, errors } = useForm<FormValues>({
  initialValues: {
    title: props.raffle?.title ?? "",
    description: props.raffle?.description,
    modelId: props.raffle?.prize?.id,
    code: undefined,
    startsAt: props.raffle?.startsAt ?? null,
    runDays: props.raffle?.runDays ?? 14,
    claimPeriodDays: props.raffle?.claimPeriodDays ?? 3,
    published: props.raffle?.published ?? false,
  },
  validationSchema: {
    title: "required",
    startsAt: "required",
    runDays: "required|min_value:1",
    claimPeriodDays: "required|min_value:1",
  },
});

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");
const [modelId, modelIdProps] = defineField("modelId");
const [code, codeProps] = defineField("code");
const [startsAt, startsAtProps] = defineField("startsAt");
const [runDays, runDaysProps] = defineField("runDays");
const [claimPeriodDays, claimPeriodDaysProps] = defineField("claimPeriodDays");
const [published, publishedProps] = defineField("published");

// Undefined until the gallery is touched, so an untouched gallery is not sent.
const imageIds = ref<string[]>();

const codeInfo = computed(() => {
  if (drawn.value) return t("labels.raffle.codeFrozen");
  if (props.raffle?.codeSet) {
    return t("labels.raffle.codeSet", { code: props.raffle.maskedCode });
  }

  return t("labels.raffle.codeInfo");
});

// FormDateTime hands back local time without an offset, and the schema wants
// RFC 3339.
const toIso = (value: string | null) =>
  value ? new Date(value).toISOString() : "";

// FormDateTime shows only the error it is handed, so a missing date would
// otherwise cancel the submit without a word on screen.
const onInvalidSubmit = () => {
  displayAlert({ text: t("messages.raffle.invalid") });
};

const onSubmit = handleSubmit((values) => {
  emit("submit", {
    title: values.title,
    description: values.description || undefined,
    modelId: values.modelId || null,
    code: values.code || undefined,
    startsAt: toIso(values.startsAt),
    runDays: Number(values.runDays),
    claimPeriodDays: Number(values.claimPeriodDays),
    images: imageIds.value,
    published: values.published,
  });
}, onInvalidSubmit);
</script>

<template>
  <form :id="formId" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="title"
          v-bind="titleProps"
          translation-key="raffle.title"
          name="title"
        />
        <ModelSelect
          v-model="modelId"
          v-bind="modelIdProps"
          :no-label="false"
          translation-key="raffle.prize"
          value-attr="id"
          name="modelId"
        />
        <FormInput
          v-model="code"
          v-bind="codeProps"
          translation-key="raffle.code"
          name="code"
          type="password"
          autocomplete="off"
          :disabled="drawn"
          :info="codeInfo"
        />
        <FormDateTime
          v-model="startsAt"
          v-bind="startsAtProps"
          translation-key="raffle.startsAt"
          name="startsAt"
          :error-message="errors.startsAt"
          :clearable="false"
          :disabled="drawn"
        />
        <FormInput
          v-model="runDays"
          v-bind="runDaysProps"
          translation-key="raffle.runDays"
          name="runDays"
          type="number"
          :disabled="drawn"
          :info="t('labels.raffle.runDaysInfo')"
        />
        <FormInput
          v-model="claimPeriodDays"
          v-bind="claimPeriodDaysProps"
          translation-key="raffle.claimPeriodDays"
          name="claimPeriodDays"
          type="number"
          :disabled="drawn"
          :info="t('labels.raffle.claimPeriodDaysInfo')"
        />
      </div>
      <div class="col-12 col-md-6">
        <RaffleGallery
          :images="raffle?.images"
          @update:signed-ids="imageIds = $event"
        />
        <FormTextarea
          v-model="description"
          v-bind="descriptionProps"
          translation-key="raffle.description"
          name="description"
        />
        <FormToggle
          v-model="published"
          v-bind="publishedProps"
          translation-key="raffle.published"
          name="published"
          no-placeholder
          :disabled="drawn"
          :info="t('labels.raffle.publishedInfo')"
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      :form-id="formId"
      :dirty="meta.dirty || meta.touched"
      @cancel="emit('cancel')"
    />
  </form>
</template>
