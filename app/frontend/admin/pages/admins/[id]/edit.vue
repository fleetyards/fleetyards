<script lang="ts">
export default {
  name: "AdminAdminUserEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type AdminUser,
  type AdminUserInput,
  type AdminUserResourceAccessEnum,
  useUpdateAdminUser,
  useResourceAccessCatalog,
  getAdminUsersQueryKey,
  getAdminUserQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  adminUser: AdminUser;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const initialValues = ref<AdminUserInput>({
  username: props.adminUser.username,
  email: props.adminUser.email,
  superAdmin: props.adminUser.superAdmin,
  resourceAccess: props.adminUser.resourceAccess,
});

const validationSchema = {
  username: "required",
  email: "required",
};

const { defineField, handleSubmit, meta } = useForm<AdminUserInput>({
  initialValues: initialValues.value,
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

const { data: resourceAccessCatalog } = useResourceAccessCatalog();

const hasPrivilege = (privilege: AdminUserResourceAccessEnum) =>
  (resourceAccess.value ?? []).includes(privilege);

const togglePrivilege = (privilege: AdminUserResourceAccessEnum) => {
  const current = resourceAccess.value ?? [];

  resourceAccess.value = current.includes(privilege)
    ? current.filter((entry) => entry !== privilege)
    : [...current, privilege];
};

const submitting = ref(false);

const updateMutation = useUpdateAdminUser({
  mutation: {
    onSettled: () => {
      const promises: Promise<void>[] = [
        queryClient.invalidateQueries({
          queryKey: getAdminUsersQueryKey(),
        }),
      ];
      if (props.adminUser.id) {
        promises.push(
          queryClient.invalidateQueries({
            queryKey: getAdminUserQueryKey(props.adminUser.id),
          }),
        );
      }
      void Promise.all(promises);
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: props.adminUser.id!, data: values })
    .catch((error) => {
      console.error("Error updating admin user:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(
    extend({
      name: "admin-admins",
      hash: `#${props.adminUser.id}`,
    }),
  );
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.admins.edit") }}</Heading>
  <form id="admin-admin-user-edit-form" @submit.prevent="onSubmit">
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
    <div v-if="!superAdmin && resourceAccessCatalog" class="resource-access">
      <h3 class="resource-access-title">
        {{ t("labels.admin.resourceAccess.title") }}
      </h3>
      <div class="resource-access-groups">
        <div
          v-for="group in resourceAccessCatalog"
          :key="group.key"
          class="resource-access-group"
        >
          <h4 class="resource-access-group-name">
            {{ t(`labels.admin.resourceAccess.groups.${group.key}`) }}
          </h4>
          <label
            v-for="privilege in group.privileges"
            :key="privilege"
            class="resource-access-item"
          >
            <input
              type="checkbox"
              :checked="hasPrivilege(privilege)"
              @change="togglePrivilege(privilege)"
            />
            {{ t(`labels.admin.resourceAccess.privileges.${privilege}`) }}
          </label>
        </div>
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="admin-admin-user-edit-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>

<style lang="scss" scoped>
.resource-access {
  margin-top: 20px;
}

.resource-access-title {
  margin: 0 0 12px;
}

.resource-access-groups {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 20px;
}

.resource-access-group-name {
  margin: 0 0 8px;
  font-size: 0.9em;
  text-transform: uppercase;
  opacity: 0.7;
}

.resource-access-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 0;
  cursor: pointer;
}
</style>
