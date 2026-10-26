<script lang="ts">
export default {
  name: "CartListModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import { useRouter } from "vue-router";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import { useCartCache } from "@/frontend/composables/useCartCache";
import {
  type CartList,
  useCreateCartList,
  useUpdateCartList,
} from "@/services/fyApi";

type Props = {
  list?: CartList;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const comlink = useComlink();
const router = useRouter();
const { refreshCarts } = useCartCache();

const initialValues = { name: props.list?.name ?? "" };

const { defineField, handleSubmit, values } = useForm({ initialValues });

useModalDirty(useFormDirty(values, initialValues));

const [name, nameProps] = defineField("name");

const createMutation = useCreateCartList();
const updateMutation = useUpdateCartList();

const submitting = computed(
  () => createMutation.isPending.value || updateMutation.isPending.value,
);

const onSubmit = handleSubmit(async (values) => {
  try {
    if (props.list) {
      await updateMutation.mutateAsync({
        id: props.list.id,
        data: { name: values.name },
      });
    } else {
      await createMutation.mutateAsync({ data: { name: values.name } });
      // A new list is the active one, which is what the page shows by default.
      await router.replace({ name: "cart" });
    }

    refreshCarts();
    comlink.emit("close-modal", true);
  } catch {
    displayAlert({ text: t("cart.lists.messages.saveFailed") });
  }
});
</script>

<template>
  <Modal :title="list ? t('cart.lists.rename') : t('cart.lists.create')">
    <form id="cart-list-form" @submit.prevent="onSubmit">
      <FormInput
        v-model="name"
        v-bind="nameProps"
        name="name"
        rules="required|max:64"
        :label="t('cart.lists.name')"
        no-placeholder
      />
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="cart-list-form"
        :loading="submitting"
        data-test="cart-list-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
