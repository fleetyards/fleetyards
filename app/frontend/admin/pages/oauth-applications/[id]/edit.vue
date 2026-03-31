<script lang="ts">
export default {
  name: "OauthApplicationEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import {
  type OauthApplication,
  type OauthApplicationInput,
  useUpdateOauthApplication,
  getOauthApplicationsQueryKey,
  getOauthApplicationQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import {
  AVAILABLE_SCOPES,
  DEFAULT_SCOPES,
} from "@/frontend/pages/settings/oauth-applications/scopes";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  oauthApplication: OauthApplication;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const initialValues = ref<OauthApplicationInput>({
  name: props.oauthApplication.name,
  redirectUri: props.oauthApplication.redirectUri,
  confidential: props.oauthApplication.confidential,
  scopes: props.oauthApplication.scopes
    ? props.oauthApplication.scopes.split(" ").filter(Boolean)
    : [],
});

const validationSchema = {
  name: "required",
  redirectUri: "required",
};

const { defineField, handleSubmit, meta } = useForm<OauthApplicationInput>({
  initialValues: initialValues.value,
  validationSchema,
});

const [name, nameProps] = defineField("name");
const [redirectUri, redirectUriProps] = defineField("redirectUri");
const [confidential, confidentialProps] = defineField("confidential");
defineField("scopes");

const submitting = ref(false);

const updateMutation = useUpdateOauthApplication();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: props.oauthApplication.id, data: values })
    .then(() => {
      void Promise.all([
        queryClient.invalidateQueries({
          queryKey: getOauthApplicationsQueryKey(),
        }),
        queryClient.invalidateQueries({
          queryKey: getOauthApplicationQueryKey(props.oauthApplication.id),
        }),
      ]);
    })
    .catch((error) => {
      console.error("Error updating OAuth application:", error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(
    extend({
      name: "admin-oauth-applications",
      hash: `#${props.oauthApplication.id}`,
    }),
  );
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      {
        to: { name: 'admin-oauth-applications' },
        label: t('nav.admin.oauthApplications.index'),
      },
      { label: oauthApplication.name },
    ]"
  />
  <Heading hero>{{ t("headlines.admin.oauthApplications.edit") }}</Heading>
  <form id="admin-oauth-application-edit-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          :model-value="oauthApplication.uid"
          name="uid"
          translation-key="oauthApplication.clientId"
          disabled
        />
        <FormInput
          :model-value="oauthApplication.secret"
          name="secret"
          translation-key="oauthApplication.clientSecret"
          disabled
        />
        <FormInput
          v-model="name"
          v-bind="nameProps"
          name="name"
          translation-key="oauthApplication.name"
        />
        <FormTextarea
          v-model="redirectUri"
          v-bind="redirectUriProps"
          translation-key="oauthApplication.redirectUri"
          name="redirectUri"
        />
        <p class="field-hint">
          {{ t("labels.oauthApplication.redirectUriHint") }}
        </p>
        <FormToggle
          v-model="confidential"
          v-bind="confidentialProps"
          translation-key="oauthApplication.confidential"
          name="confidential"
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
      form-id="admin-oauth-application-edit-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>

<style lang="scss" scoped>
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
