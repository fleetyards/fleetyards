<script lang="ts">
export default {
  name: "GameEventForm",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import {
  type FilterOption,
  type GameEvent,
  type GameEventInput,
  GameEventCategoryEnum,
} from "@/services/fyAdminApi";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  formId: string;
  gameEvent?: GameEvent;
  submitting?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  gameEvent: undefined,
  submitting: false,
});

const emit = defineEmits<{
  submit: [payload: GameEventInput];
  cancel: [];
}>();

const { t } = useI18n();

type FormValues = {
  title: string;
  description?: string;
  location?: string;
  url?: string;
  category: GameEventCategoryEnum;
  startsAt: string | null;
  endsAt: string | null;
  published: boolean;
  // A signed blob id replaces the picture, null removes it, and undefined
  // leaves what is attached.
  coverImage?: string | null;
};

const { defineField, handleSubmit, meta } = useForm<FormValues>({
  initialValues: {
    title: props.gameEvent?.title ?? "",
    description: props.gameEvent?.description,
    location: props.gameEvent?.location,
    url: props.gameEvent?.url,
    category: props.gameEvent?.category ?? GameEventCategoryEnum.OTHER,
    startsAt: props.gameEvent?.startsAt ?? null,
    endsAt: props.gameEvent?.endsAt ?? null,
    published: props.gameEvent?.published ?? false,
    coverImage: undefined,
  },
  validationSchema: {
    title: "required",
    startsAt: "required",
    url: "url",
  },
});

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");
const [location, locationProps] = defineField("location");
const [url, urlProps] = defineField("url");
const [category, categoryProps] = defineField("category");
const [startsAt, startsAtProps] = defineField("startsAt");
const [endsAt, endsAtProps] = defineField("endsAt");
const [published, publishedProps] = defineField("published");
const [coverImage, coverImageProps] = defineField("coverImage");

const categoryOptions = computed<FilterOption[]>(() =>
  Object.values(GameEventCategoryEnum).map((value) => ({
    value,
    label: t(`labels.fleets.missions.categories.${value}`),
  })),
);

// FormDateTime hands back local time without an offset, and the schema wants
// RFC 3339.
const toIso = (value: string | null) =>
  value ? new Date(value).toISOString() : null;

const onSubmit = handleSubmit((values) => {
  emit("submit", {
    title: values.title,
    description: values.description || undefined,
    location: values.location || undefined,
    url: values.url || undefined,
    category: values.category,
    startsAt: toIso(values.startsAt) as string,
    endsAt: toIso(values.endsAt),
    published: values.published,
    coverImage: values.coverImage,
  });
});
</script>

<template>
  <form :id="formId" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="title"
          v-bind="titleProps"
          translation-key="gameEvent.title"
          name="title"
        />
        <BaseSelect
          v-model="category"
          v-bind="categoryProps"
          :options="categoryOptions"
          :label="t('labels.gameEvent.category')"
          name="category"
          :searchable="false"
        />
        <FormDateTime
          v-model="startsAt"
          v-bind="startsAtProps"
          translation-key="gameEvent.startsAt"
          name="startsAt"
          :clearable="false"
        />
        <FormDateTime
          v-model="endsAt"
          v-bind="endsAtProps"
          translation-key="gameEvent.endsAt"
          name="endsAt"
        />
        <FormInput
          v-model="location"
          v-bind="locationProps"
          translation-key="gameEvent.location"
          name="location"
        />
        <FormInput
          v-model="url"
          v-bind="urlProps"
          translation-key="gameEvent.url"
          name="url"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormFileInput
          v-model="coverImage"
          v-bind="coverImageProps"
          :file="gameEvent?.coverImage"
          translation-key="gameEvent.coverImage"
          name="coverImage"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
        />
        <FormTextarea
          v-model="description"
          v-bind="descriptionProps"
          translation-key="gameEvent.description"
          name="description"
        />
        <FormToggle
          v-model="published"
          v-bind="publishedProps"
          translation-key="gameEvent.published"
          name="published"
          no-placeholder
          :info="t('labels.gameEvent.publishedInfo')"
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
