<script lang="ts">
export default {
  name: "VehiclePlaqueEditModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import LocationInput from "@/shared/components/LocationInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { OPERATIONS_GROUPS } from "@/frontend/components/Vehicles/Plaque/operationsGroups";
import { plaqueMakerFor } from "@/frontend/components/Vehicles/Plaque/makers";
import VehiclePlaque from "@/frontend/components/Vehicles/Plaque/index.vue";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import {
  NullableVehiclePlaqueStyleEnum,
  type Vehicle,
  type VehiclePlaqueStyleEnum,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const DEDICATION_LIMIT = 280;
const LINE_LIMIT = 100;

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const vehicle = computed(() => props.vehicle);

const { currentUser } = storeToRefs(useSessionStore());

const maker = computed(() => plaqueMakerFor(props.vehicle));

// A maker with a style of its own gets it by default: it is the plaque made
// for that ship.
const defaultStyle = computed<VehiclePlaqueStyleEnum>(() =>
  maker.value ? "manufacturer" : "brass",
);

const validationSchema = {
  dedication: `max:${DEDICATION_LIMIT}`,
  launchPort: `max:${LINE_LIMIT}`,
  affiliation: `max:${LINE_LIMIT}`,
};

const { defineField, handleSubmit } = useForm({
  initialValues: {
    dedication: props.vehicle.dedication ?? "",
    launchedOn: props.vehicle.launchedOn ?? null,
    launchPort: props.vehicle.launchPort ?? "",
    launchPortLocationId: props.vehicle.launchPortLocation?.id ?? null,
    affiliation: props.vehicle.affiliation ?? "",
    operationsGroup: props.vehicle.operationsGroup ?? null,
    plaqueStyle: props.vehicle.dedication
      ? (props.vehicle.plaqueStyle ?? defaultStyle.value)
      : defaultStyle.value,
  },
});

const [dedication] = defineField("dedication");
const [launchedOn] = defineField("launchedOn");
const [launchPort] = defineField("launchPort");
const [launchPortLocationId] = defineField("launchPortLocationId");
const [affiliation] = defineField("affiliation");
const [operationsGroup] = defineField("operationsGroup");
const [plaqueStyle] = defineField("plaqueStyle");

const plaqueStyleOptions = computed(() =>
  Object.values(NullableVehiclePlaqueStyleEnum)
    .filter((style): style is VehiclePlaqueStyleEnum => !!style)
    .filter((style) => style !== "manufacturer" || !!maker.value)
    .map((style) => ({
      value: style,
      label: t(`labels.vehiclePlaque.styles.${style}`),
    })),
);

// The plaque as it will read once saved, so a style is picked by looking at it.
const preview = computed<Vehicle>(() => ({
  ...props.vehicle,
  dedication: dedication.value || null,
  launchedOn: launchedOn.value || null,
  launchPort: launchPort.value || null,
  affiliation: affiliation.value || null,
  operationsGroup: operationsGroup.value || null,
  plaqueStyle: plaqueStyle.value,
}));

// Grouped by side of the law, lawful first, as the select keeps this order.
const operationsGroupOptions = computed(() =>
  Object.entries(OPERATIONS_GROUPS).map(([value, group]) => ({
    value,
    label: `${group.name} · ${t(`labels.fleet.alignments.${group.alignment}`)}`,
  })),
);

// The fleets the ship is listed in, offered as the organization it serves.
const fleetNames = computed(() =>
  (props.vehicle.fleets ?? []).map((fleet) => fleet.name),
);

const { useUpdateMutation } = useVehicleMutations();
const updateMutation = useUpdateMutation(vehicle);

// The payload carries the style the plaque is drawn in, not the stored choice,
// so it is only sent once picked: otherwise saving any line would pin the
// default as a choice of its own.
const initialPlaqueStyle = plaqueStyle.value;

const onSubmit = handleSubmit(async (values) => {
  await updateMutation
    .mutateAsync({
      id: props.vehicle.id,
      // Null rather than left out: a cleared field clears the line.
      data: {
        dedication: values.dedication || null,
        launchedOn: values.launchedOn || null,
        launchPort: values.launchPort || null,
        launchPortLocationId: values.launchPortLocationId ?? null,
        affiliation: values.affiliation || null,
        operationsGroup: values.operationsGroup || null,
        ...(values.plaqueStyle !== initialPlaqueStyle
          ? { plaqueStyle: values.plaqueStyle || null }
          : {}),
      },
    })
    .then(() => comlink.emit("close-modal"))
    .catch(() => {
      displayAlert({ text: t("messages.vehiclePlaque.failure") });
    });
});
</script>

<template>
  <Modal :title="t('headlines.vehiclePlaque.title')">
    <VehiclePlaque
      :vehicle="preview"
      :captain="currentUser?.username"
      class="plaque-edit__preview"
      data-test="vehicle-plaque-preview"
    />
    <form id="vehicle-plaque-form" @submit.prevent="onSubmit">
      <BaseSelect
        v-model="plaqueStyle"
        :options="plaqueStyleOptions"
        :label="t('labels.vehiclePlaque.style')"
        name="plaqueStyle"
        :searchable="false"
        :nullable="false"
        unsorted
        data-test="vehicle-plaque-style"
      />
      <FormTextarea
        v-model="dedication"
        name="dedication"
        :label="t('labels.vehiclePlaque.dedication')"
        :rules="validationSchema.dedication"
        :maxlength="DEDICATION_LIMIT"
        data-test="vehicle-plaque-dedication-input"
      />
      <FormDatePicker
        v-model="launchedOn"
        name="launchedOn"
        :label="t('labels.vehiclePlaque.launchedOn')"
        clearable
      />
      <LocationInput
        v-model="launchPort"
        v-model:location-id="launchPortLocationId"
        :linked="vehicle.launchPortLocation"
        name="launchPort"
        :label="t('labels.vehiclePlaque.launchPort')"
        :rules="validationSchema.launchPort"
      />
      <FormInput
        v-model="affiliation"
        name="affiliation"
        :label="t('labels.vehiclePlaque.affiliation')"
        :rules="validationSchema.affiliation"
      />
      <div v-if="fleetNames.length" class="plaque-edit__fleets">
        <span class="text-muted">{{ t("texts.vehiclePlaque.fromFleet") }}</span>
        <Btn
          v-for="fleetName in fleetNames"
          :key="fleetName"
          :size="BtnSizesEnum.XS"
          data-test="vehicle-plaque-fleet"
          @click="affiliation = fleetName"
        >
          {{ fleetName }}
        </Btn>
      </div>
      <BaseSelect
        v-model="operationsGroup"
        :options="operationsGroupOptions"
        :label="t('labels.vehiclePlaque.operationsGroup')"
        name="operationsGroup"
        :searchable="false"
        unsorted
        nullable
      />
      <p class="text-muted">{{ t("texts.vehiclePlaque.visibility") }}</p>
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="vehicle-plaque-form"
        :loading="updateMutation.isPending.value"
        data-test="vehicle-plaque-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.plaque-edit__preview {
  margin-bottom: 20px;
}

.plaque-edit__fleets {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  margin: -8px 0 16px;
}
</style>
