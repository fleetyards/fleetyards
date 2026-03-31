<script lang="ts">
export default {
  name: "SettingsOauthApplicationCreate",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import {
  type OauthApplicationInput,
  createOauthApplication,
  getOauthApplicationsQueryKey,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";
import { useForm } from "vee-validate";
import {
  AVAILABLE_SCOPES,
  DEFAULT_SCOPES,
} from "@/frontend/pages/settings/oauth-applications/scopes";

const { t } = useI18n();
const router = useRouter();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

const validationSchema = {
  name: "required",
  redirectUri: "required",
};

const { defineField, handleSubmit, meta } = useForm<OauthApplicationInput>({
  initialValues: {
    name: "",
    redirectUri: "",
    confidential: true,
    scopes: [] as string[],
  },
  validationSchema,
});

const [name, nameProps] = defineField("name");
const [redirectUri, redirectUriProps] = defineField("redirectUri");
const [confidential, confidentialProps] = defineField("confidential");
defineField("scopes");

const submitting = ref(false);

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;
  try {
    const result = await createOauthApplication(values);
    void queryClient.invalidateQueries({
      queryKey: getOauthApplicationsQueryKey(),
    });
    displaySuccess({ text: t("messages.oauthApplications.create.success") });
    await router.push({
      name: "settings-oauth-application",
      params: { id: result.id },
      query: { secret: result.secret },
    });
  } catch {
    displayAlert({ text: t("messages.oauthApplications.create.error") });
  } finally {
    submitting.value = false;
  }
});

const handleCancel = async () => {
  await router.push({ name: "settings-oauth-applications" });
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      { to: { name: 'settings' }, label: t('nav.settings.index') },
      {
        to: { name: 'settings-oauth-applications' },
        label: t('nav.settings.oauthApplications'),
      },
    ]"
  />

  <Heading hero>{{ t("headlines.oauthApplications.new") }}</Heading>

  <form
    id="settings-oauth-application-create-form"
    class="oauth-form"
    @submit.prevent="onSubmit"
  >
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="name"
          v-bind="nameProps"
          name="name"
          translation-key="oauthApplication.name"
        />
        <FormTextarea
          v-model="redirectUri"
          v-bind="redirectUriProps"
          name="redirectUri"
          translation-key="oauthApplication.redirectUri"
        />
        <p class="field-hint">
          {{ t("labels.oauthApplication.redirectUriHint") }}
        </p>
        <FormToggle
          v-model="confidential"
          v-bind="confidentialProps"
          name="confidential"
          translation-key="oauthApplication.confidential"
        />

        <span class="scopes-label" role="heading" aria-level="3">
          {{ t("labels.oauthApplications.scopes") }}
        </span>
        <p class="scopes-hint">
          {{
            t("labels.oauthApplication.scopesHint", {
              scopes: DEFAULT_SCOPES.join(", "),
            })
          }}
        </p>
        <div class="scopes-grid">
          <FormCheckbox
            v-for="scope in AVAILABLE_SCOPES"
            :key="scope"
            name="scopes"
            :checkbox-value="scope"
            :label="scope"
          />
        </div>
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="settings-oauth-application-create-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>

<style lang="scss" scoped>
.oauth-form {
  margin-top: 1.5rem;
}

.scopes-label {
  display: block;
  font-weight: 600;
  margin-bottom: 0.25rem;
}

.field-hint,
.scopes-hint {
  font-size: 0.85rem;
  opacity: 0.6;
  margin-bottom: 0.75rem;
}

.scopes-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.25rem 1rem;
  margin-bottom: 1rem;
}
</style>
