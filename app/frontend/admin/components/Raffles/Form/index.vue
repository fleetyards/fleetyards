<script lang="ts">
export default {
  name: "RaffleForm",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import {
  type Raffle,
  type RaffleInput,
  type RaffleTranslation,
  RaffleTranslationLocaleEnum,
} from "@/services/fyAdminApi";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormMarkdownEditor from "@/shared/components/base/FormMarkdownEditor/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import FormTabs from "@/shared/components/base/FormTabs/index.vue";
import FormTab from "@/shared/components/base/FormTabs/Tab/index.vue";
import RaffleGallery from "@/admin/components/Raffles/Gallery/index.vue";
import { readRaffleFolder } from "@/admin/components/Raffles/Form/folderImport";
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

const { t, currentLocale } = useI18n();

const { displayAlert, displaySuccess, displayWarning } = useAppNotifications();

const drawn = computed(() => !!props.raffle?.drawnAt);

const LOCALES = Object.values(RaffleTranslationLocaleEnum);

type TranslationValues = Omit<RaffleTranslation, "locale">;

type FormValues = {
  title: string;
  prize?: string;
  description?: string;
  translations: Record<RaffleTranslationLocaleEnum, TranslationValues>;
  // Never filled from the server: the API only says whether a code is set.
  code?: string;
  startsAt: string | null;
  runDays: number;
  claimPeriodDays: number;
  published: boolean;
};

const { defineField, handleSubmit, meta, errors, setFieldValue } =
  useForm<FormValues>({
    initialValues: {
      title: props.raffle?.title ?? "",
      prize: props.raffle?.prize,
      description: props.raffle?.description,
      translations: Object.fromEntries(
        LOCALES.map((locale) => {
          const stored = props.raffle?.translations.find(
            (translation) => translation.locale === locale,
          );

          return [
            locale,
            {
              title: stored?.title,
              prize: stored?.prize,
              description: stored?.description,
            },
          ];
        }),
      ) as FormValues["translations"],
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
const [prize, prizeProps] = defineField("prize");
const [description, descriptionProps] = defineField("description");

const translationField = (
  locale: RaffleTranslationLocaleEnum,
  field: keyof TranslationValues,
) => defineField(`translations.${locale}.${field}` as `translations.de.title`);

const translationFields = Object.fromEntries(
  LOCALES.map((locale) => [
    locale,
    {
      title: translationField(locale, "title"),
      prize: translationField(locale, "prize"),
      description: translationField(locale, "description"),
    },
  ]),
) as Record<
  RaffleTranslationLocaleEnum,
  Record<keyof TranslationValues, ReturnType<typeof translationField>>
>;

// Named in the admin's own language, so no label per locale has to be kept.
// The admin remounts on a language switch, so one instance per mount holds.
const languageNames = new Intl.DisplayNames([currentLocale()], {
  type: "language",
});

const languageName = (locale: string) => languageNames.of(locale) ?? locale;

const hasTranslation = (locale: RaffleTranslationLocaleEnum) =>
  Object.values(translationFields[locale]).some(([value]) => !!value.value);

const [code, codeProps] = defineField("code");
const [startsAt, startsAtProps] = defineField("startsAt");
const [runDays, runDaysProps] = defineField("runDays");
const [claimPeriodDays, claimPeriodDaysProps] = defineField("claimPeriodDays");
const [published, publishedProps] = defineField("published");

// Undefined until the gallery is touched, so an untouched gallery is not sent.
const imageIds = ref<string[]>();

const gallery = ref<InstanceType<typeof RaffleGallery>>();

const folderInput = ref<HTMLInputElement>();

const importing = ref(false);

// Fills the form from a folder of `<locale>.md` files and images. Only the
// fields a file holds are set, and nothing is saved until the admin submits.
const importFolder = async (event: Event) => {
  const input = event.target as HTMLInputElement;
  const files = Array.from(input.files ?? []);
  input.value = "";

  if (!files.length) return;

  importing.value = true;

  try {
    const folder = await readRaffleFolder(files, ["en", ...LOCALES]);

    Object.entries(folder.texts).forEach(([locale, text]) => {
      const prefix = locale === "en" ? "" : `translations.${locale}.`;

      Object.entries(text).forEach(([field, value]) => {
        setFieldValue(`${prefix}${field}` as "title", value);
      });
    });

    const languages = Object.keys(folder.texts).length;

    if (!languages && !folder.images.length) {
      displayAlert({ text: t("messages.raffle.importEmpty") });
      return;
    }

    if (folder.skipped.length) {
      displayWarning({
        text: t("messages.raffle.importSkipped", {
          files: folder.skipped.join(", "),
        }),
      });
    }

    const failed = (await gallery.value?.addFiles(folder.images)) ?? [];

    if (failed.length) {
      displayAlert({
        text: t("messages.raffle.importUploadFailed", {
          files: failed.map((file) => file.name).join(", "),
        }),
      });
    }

    displaySuccess({
      text: t("messages.raffle.imported", {
        languages,
        images: folder.images.length - failed.length,
      }),
    });
  } finally {
    importing.value = false;
  }
};

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
    prize: values.prize || undefined,
    description: values.description || undefined,
    translations: LOCALES.map((locale) => ({
      locale,
      title: values.translations[locale]?.title || undefined,
      prize: values.translations[locale]?.prize || undefined,
      description: values.translations[locale]?.description || undefined,
    })).filter(
      (translation) =>
        translation.title || translation.prize || translation.description,
    ),
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
    <div class="raffle-form__import">
      <Btn
        size="sm"
        :loading="importing"
        data-test="raffle-import-folder"
        @click="folderInput?.click()"
      >
        <i class="fa-light fa-folder-open" />
        {{ t("actions.raffle.importFolder") }}
      </Btn>
      <p class="raffle-form__info">
        {{ t("labels.raffle.importFolderInfo") }}
      </p>
      <input
        ref="folderInput"
        type="file"
        class="raffle-form__folder-input"
        webkitdirectory
        multiple
        data-test="raffle-import-input"
        @change="importFolder"
      />
    </div>
    <FormTabs :sync-url="false" horizontal>
      <FormTab id="en" :label="languageName('en')" :fields="['title']">
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="title"
              v-bind="titleProps"
              translation-key="raffle.title"
              name="title"
            />
            <FormInput
              v-model="prize"
              v-bind="prizeProps"
              translation-key="raffle.prize"
              name="prize"
              :info="t('labels.raffle.prizeInfo')"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormMarkdownEditor
              v-model="description"
              v-bind="descriptionProps"
              translation-key="raffle.description"
              name="description"
              :info="t('labels.raffle.descriptionInfo')"
            />
          </div>
        </div>
      </FormTab>
      <FormTab
        v-for="locale in LOCALES"
        :id="locale"
        :key="locale"
        :label="languageName(locale)"
        :icon="hasTranslation(locale) ? 'fa-duotone fa-check' : undefined"
      >
        <p class="raffle-form__info">
          {{ t("labels.raffle.translationInfo") }}
        </p>
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="translationFields[locale].title[0].value"
              v-bind="translationFields[locale].title[1].value"
              translation-key="raffle.title"
              :name="`translations.${locale}.title`"
              :placeholder="title"
            />
            <FormInput
              v-model="translationFields[locale].prize[0].value"
              v-bind="translationFields[locale].prize[1].value"
              translation-key="raffle.prize"
              :name="`translations.${locale}.prize`"
              :placeholder="prize"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormMarkdownEditor
              v-model="translationFields[locale].description[0].value"
              v-bind="translationFields[locale].description[1].value"
              translation-key="raffle.description"
              :name="`translations.${locale}.description`"
            />
          </div>
        </div>
      </FormTab>
    </FormTabs>
    <div class="row">
      <div class="col-12 col-md-6">
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
          ref="gallery"
          :images="raffle?.images"
          @update:signed-ids="imageIds = $event"
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

<style lang="scss" scoped>
.raffle-form__import {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;

  .raffle-form__info {
    margin: 0;
  }
}

.raffle-form__folder-input {
  display: none;
}

.raffle-form__info {
  margin: 0 0 12px;
  color: var(--color-text-dim, #959595);
  font-size: 0.875rem;
}
</style>
