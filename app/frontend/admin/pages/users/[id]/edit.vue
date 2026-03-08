<script lang="ts">
export default {
  name: "AdminUserEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type User,
  type UserInput,
  useUpdateUser,
  getUsersQueryKey,
  getUserQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  user: User;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const initialValues = ref<UserInput>({
  username: props.user.username,
  email: props.user.email,
  rsiHandle: props.user.rsiHandle,
  saleNotify: props.user.saleNotify,
  publicHangar: props.user.publicHangar,
  publicHangarLoaners: props.user.publicHangarLoaners,
  publicWishlist: props.user.publicWishlist,
  hideOwner: props.user.hideOwner,
  tester: undefined,
});

const validationSchema = {
  username: "required",
  email: "required",
};

const { defineField, handleSubmit, meta } = useForm<UserInput>({
  initialValues: initialValues.value,
  validationSchema,
});

const [username, usernameProps] = defineField("username");
const [email, emailProps] = defineField("email");
const [rsiHandle, rsiHandleProps] = defineField("rsiHandle");
const [saleNotify, saleNotifyProps] = defineField("saleNotify");
const [publicHangar, publicHangarProps] = defineField("publicHangar");
const [publicHangarLoaners, publicHangarLoanersProps] = defineField(
  "publicHangarLoaners",
);
const [publicWishlist, publicWishlistProps] = defineField("publicWishlist");
const [hideOwner, hideOwnerProps] = defineField("hideOwner");
const [tester, testerProps] = defineField("tester");

const submitting = ref(false);

const updateMutation = useUpdateUser({
  mutation: {
    onSettled: async () => {
      await queryClient.invalidateQueries({
        queryKey: getUsersQueryKey(),
      });
      if (props.user.id) {
        await queryClient.invalidateQueries({
          queryKey: getUserQueryKey(props.user.id),
        });
      }
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: props.user.id!, data: values })
    .catch((error) => {
      console.error("Error updating user:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(
    extend({
      name: "admin-users",
      hash: `#${props.user.id}`,
    }),
  );
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.users.edit") }}</Heading>
  <form @submit.prevent="onSubmit" id="admin-user-edit-form">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="username" v-bind="usernameProps" name="username" />
        <FormInput v-model="email" v-bind="emailProps" name="email" />
        <FormInput
          v-model="rsiHandle"
          v-bind="rsiHandleProps"
          translation-key="user.rsiHandle"
          name="rsiHandle"
        />
      </div>
      <div class="col-12 col-md-6">
        <div class="row">
          <div class="col-12 col-md-6">
            <FormCheckbox
              v-model="saleNotify"
              translation-key="user.saleNotify"
              v-bind="saleNotifyProps"
              name="saleNotify"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormCheckbox
              v-model="tester"
              translation-key="user.tester"
              v-bind="testerProps"
              name="tester"
            />
          </div>
        </div>
        <hr />
        <div class="row">
          <div class="col-12 col-md-6">
            <FormCheckbox
              v-model="publicHangar"
              translation-key="user.publicHangar"
              v-bind="publicHangarProps"
              name="publicHangar"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormCheckbox
              v-model="publicHangarLoaners"
              translation-key="user.publicHangarLoaners"
              v-bind="publicHangarLoanersProps"
              name="publicHangarLoaners"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-6">
            <FormCheckbox
              v-model="publicWishlist"
              translation-key="user.publicWishlist"
              v-bind="publicWishlistProps"
              name="publicWishlist"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormCheckbox
              v-model="hideOwner"
              translation-key="user.hideOwner"
              v-bind="hideOwnerProps"
              name="hideOwner"
            />
          </div>
        </div>
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      formId="admin-user-edit-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
