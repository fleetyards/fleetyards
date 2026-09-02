<script lang="ts">
export default {
  name: "AdminAdminUserCreatePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import {
  type AdminUserInput,
  useCreateAdminUser,
  getAdminUsersQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import AdminUserResourceAccess from "@/admin/components/AdminUsers/ResourceAccess/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useQueryClient } from "@tanstack/vue-query";

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();
const { displayAlert } = useAppNotifications();

const validationSchema = {
  username: "required|alpha_dash",
  email: "required|email",
  password: "required|min:8",
  passwordConfirmation: "required|confirmed:@password",
};

const { defineField, handleSubmit, meta, setErrors } = useForm<AdminUserInput>({
  initialValues: {
    username: "",
    email: "",
    password: "",
    passwordConfirmation: "",
    superAdmin: false,
    resourceAccess: [],
  },
  validationSchema,
});

const [username, usernameProps] = defineField("username");
const [email, emailProps] = defineField("email");
const [password, passwordProps] = defineField("password");
const [passwordConfirmation, passwordConfirmationProps] = defineField(
  "passwordConfirmation",
);
const [superAdmin, superAdminProps] = defineField("superAdmin");
const [resourceAccess] = defineField("resourceAccess");

const submitting = ref(false);

const createMutation = useCreateAdminUser();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await createMutation
    .mutateAsync({ data: values })
    .then(async (created) => {
      void queryClient.invalidateQueries({
        queryKey: getAdminUsersQueryKey(),
      });
      await router.push(
        extend({
          name: "admin-admin-edit",
          params: { id: created.id! },
        }),
      );
    })
    .catch((error) => {
      const { message, formErrors } = validationErrorFrom(error);

      setErrors(formErrors);

      displayAlert({
        text: message || t("errors.generic"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(extend({ name: "admin-admins" }));
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      {
        to: { name: 'admin-admins' },
        label: t('nav.admin.admins.index'),
      },
    ]"
  />
  <Heading hero>{{ t("headlines.admin.admins.new") }}</Heading>
  <form id="admin-admin-user-create-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="username" v-bind="usernameProps" name="username" />
        <FormInput v-model="email" v-bind="emailProps" name="email" />
        <FormToggle
          v-model="superAdmin"
          v-bind="superAdminProps"
          translation-key="adminUser.superAdmin"
          name="superAdmin"
          align-with-fields
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="password"
          v-bind="passwordProps"
          type="password"
          name="password"
        />
        <FormInput
          v-model="passwordConfirmation"
          v-bind="passwordConfirmationProps"
          translation-key="adminUser.passwordConfirmation"
          type="password"
          name="passwordConfirmation"
        />
      </div>
    </div>
    <AdminUserResourceAccess v-if="!superAdmin" v-model="resourceAccess" />
    <FormActions
      :submitting="submitting"
      form-id="admin-admin-user-create-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
