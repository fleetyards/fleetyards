<script lang="ts">
export default {
  name: "AdminVehicleEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type Vehicle,
  type VehicleInput,
  useUpdateVehicle,
  getVehiclesQueryKey,
  getVehicleQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const initialValues = ref<VehicleInput>({
  name: props.vehicle.name,
  serial: props.vehicle.serial,
  wanted: props.vehicle.wanted,
  flagship: props.vehicle.flagship,
  public: props.vehicle.public,
  nameVisible: props.vehicle.nameVisible,
  saleNotify: props.vehicle.saleNotify,
  hidden: props.vehicle.hidden,
  loaner: props.vehicle.loaner,
});

const { defineField, handleSubmit, meta } = useForm<VehicleInput>({
  initialValues: initialValues.value,
});

const [name, nameProps] = defineField("name");
const [serial, serialProps] = defineField("serial");
const [wanted, wantedProps] = defineField("wanted");
const [flagship, flagshipProps] = defineField("flagship");
const [publicField, publicProps] = defineField("public");
const [nameVisible, nameVisibleProps] = defineField("nameVisible");
const [saleNotify, saleNotifyProps] = defineField("saleNotify");
const [hidden, hiddenProps] = defineField("hidden");
const [loaner, loanerProps] = defineField("loaner");

const submitting = ref(false);

const updateMutation = useUpdateVehicle({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({
          queryKey: getVehiclesQueryKey(),
        }),
        queryClient.invalidateQueries({
          queryKey: getVehicleQueryKey(props.vehicle.id),
        }),
      ]);
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: props.vehicle.id, data: values })
    .catch((error) => {
      console.error("Error updating vehicle:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(
    extend({
      name: "admin-vehicles",
      hash: `#${props.vehicle.id}`,
    }),
  );
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.vehicles.edit") }}</Heading>
  <form id="admin-vehicle-edit-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="name" v-bind="nameProps" name="name" />
        <FormInput
          v-model="serial"
          v-bind="serialProps"
          translation-key="vehicle.serial"
          name="serial"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="wanted"
          v-bind="wantedProps"
          translation-key="vehicle.wanted"
          name="wanted"
        />
        <FormToggle
          v-model="flagship"
          v-bind="flagshipProps"
          translation-key="vehicle.flagship"
          name="flagship"
        />
        <FormToggle
          v-model="publicField"
          v-bind="publicProps"
          translation-key="vehicle.public"
          name="public"
        />
        <FormToggle
          v-model="nameVisible"
          v-bind="nameVisibleProps"
          translation-key="vehicle.nameVisible"
          name="nameVisible"
        />
        <FormToggle
          v-model="saleNotify"
          v-bind="saleNotifyProps"
          translation-key="vehicle.saleNotify"
          name="saleNotify"
        />
        <FormToggle
          v-model="hidden"
          v-bind="hiddenProps"
          translation-key="vehicle.hidden"
          name="hidden"
        />
        <FormToggle
          v-model="loaner"
          v-bind="loanerProps"
          translation-key="vehicle.loaner"
          name="loaner"
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="admin-vehicle-edit-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
