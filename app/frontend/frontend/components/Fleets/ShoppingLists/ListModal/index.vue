<script lang="ts">
export default {
  name: "FleetShoppingListModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import { useQueryClient } from "@tanstack/vue-query";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import SquadronSelect from "@/frontend/components/Fleets/Squadrons/SquadronSelect/index.vue";
import { useSquadronVisibility } from "@/frontend/composables/useSquadronVisibility";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import {
  type FilterOption,
  type Fleet,
  type FleetShoppingList,
  FleetShoppingListVisibilityEnum,
  getFleetShoppingListQueryKey,
  getFleetShoppingListsQueryKey,
  useCartLists,
  useCreateFleetShoppingList,
  useUpdateFleetShoppingList,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  list?: FleetShoppingList;
};

const props = withDefaults(defineProps<Props>(), {
  list: undefined,
});

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const queryClient = useQueryClient();

const isEdit = computed(() => !!props.list);

const initialValues = {
  cartId: null as string | null,
  name: props.list?.name ?? "",
  description: props.list?.description ?? "",
  visibility:
    props.list?.visibility ?? FleetShoppingListVisibilityEnum.MEMBERS_ONLY,
  fleetSquadronIds: (props.list?.fleetSquadrons ?? []).map(
    (squadron) => squadron.id,
  ),
};

const { defineField, handleSubmit, values } = useForm({ initialValues });

useModalDirty(useFormDirty(values, initialValues));

const [cartId, cartIdProps] = defineField("cartId");
const [name, nameProps] = defineField("name");
const [description, descriptionProps] = defineField("description");
const [visibility, visibilityProps] = defineField("visibility");
const [fleetSquadronIds] = defineField("fleetSquadronIds");

const { data: carts } = useCartLists();

const cartOptions = computed<FilterOption[]>(() =>
  (carts.value ?? [])
    .filter((cart) => cart.itemsCount > 0)
    .map((cart) => ({
      value: cart.id,
      label: `${cart.name} (${cart.itemsCount})`,
    })),
);

// A new list takes the name of the one it is published from, and follows a
// change of source, until somebody types a name of their own.
const sourceName = (id: string | null) =>
  carts.value?.find((cart) => cart.id === id)?.name ?? "";

watch(cartId, (id, previous) => {
  if (isEdit.value) return;
  if (name.value && name.value !== sourceName(previous)) return;

  name.value = sourceName(id);
});

const restrictedToSquadrons = computed(
  () => visibility.value === FleetShoppingListVisibilityEnum.SQUADRON_ONLY,
);

const { withSquadronChoice } = useSquadronVisibility(
  () => props.fleet,
  FleetShoppingListVisibilityEnum.SQUADRON_ONLY,
  visibility,
);

const visibilityOptions = computed<FilterOption[]>(() =>
  withSquadronChoice(
    Object.values(FleetShoppingListVisibilityEnum).map((value) => ({
      value,
      label: t(`labels.logistics.visibilities.${value}`),
    })),
  ),
);

const submitting = ref(false);

const createMutation = useCreateFleetShoppingList();
const updateMutation = useUpdateFleetShoppingList();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const fields = {
    name: values.name,
    description: values.description || null,
    visibility: values.visibility,
    fleetSquadronIds: restrictedToSquadrons.value
      ? (values.fleetSquadronIds ?? [])
      : [],
  };

  const mutation = isEdit.value
    ? updateMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        id: props.list!.id,
        data: {
          ...fields,
          ...(values.cartId ? { cartId: values.cartId } : {}),
        },
      })
    : createMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        data: { ...fields, cartId: values.cartId! },
      });

  await mutation
    .then((saved) => {
      void queryClient.invalidateQueries({
        queryKey: getFleetShoppingListsQueryKey(props.fleet.slug),
      });
      void queryClient.invalidateQueries({
        queryKey: getFleetShoppingListQueryKey(props.fleet.slug, saved.id),
      });
      displaySuccess({
        text: isEdit.value
          ? t("cart.fleetLists.messages.updated", { name: saved.name })
          : t("cart.fleetLists.messages.published", { name: saved.name }),
      });
      comlink.emit("close-modal", true);
    })
    .catch(() => {
      displayAlert({ text: t("cart.fleetLists.messages.saveFailed") });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <Modal
    :title="
      isEdit
        ? t('cart.fleetLists.editTitle')
        : t('cart.fleetLists.publishTitle')
    "
  >
    <form id="fleet-shopping-list-form" @submit.prevent="onSubmit">
      <BaseSelect
        v-model="cartId"
        v-bind="cartIdProps"
        name="cartId"
        :options="cartOptions"
        :label="
          isEdit
            ? t('cart.fleetLists.replaceFrom')
            : t('cart.fleetLists.source')
        "
        :info="
          isEdit
            ? t('cart.fleetLists.replaceHint')
            : t('cart.fleetLists.sourceHint')
        "
        :nullable="isEdit"
        :searchable="false"
        unsorted
      />
      <FormInput
        v-model="name"
        v-bind="nameProps"
        name="name"
        rules="required|max:64"
        :label="t('cart.lists.name')"
        data-test="fleet-shopping-list-name"
      />
      <FormTextarea
        v-model="description"
        v-bind="descriptionProps"
        name="description"
        rules="max:1000"
        :label="t('cart.fleetLists.description')"
      />
      <BaseSelect
        v-model="visibility"
        v-bind="visibilityProps"
        name="visibility"
        :options="visibilityOptions"
        :label="t('labels.logistics.visibility')"
        :searchable="false"
      />
      <SquadronSelect
        v-if="restrictedToSquadrons"
        v-model="fleetSquadronIds"
        :fleet="props.fleet"
        :assigned="props.list?.fleetSquadrons"
      />
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="fleet-shopping-list-form"
        :loading="submitting"
        :disabled="!isEdit && !cartId"
        data-test="fleet-shopping-list-submit"
      >
        {{ isEdit ? t("actions.save") : t("cart.fleetLists.publish") }}
      </Btn>
    </template>
  </Modal>
</template>
