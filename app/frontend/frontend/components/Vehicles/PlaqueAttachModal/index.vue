<script lang="ts">
export default {
  name: "VehiclePlaqueAttachModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import RadioList from "@/shared/components/base/RadioList/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import PlaqueCapture from "@/frontend/components/Vehicles/PlaqueCapture/index.vue";
import { type PlaqueLines } from "@/frontend/components/Vehicles/PlaqueAttachModal/types";
import { usePlaqueImageUpload } from "@/frontend/composables/usePlaqueImageUpload";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useHangar,
  useUpdateVehicle,
  type Model,
  type Vehicle,
} from "@/services/fyApi";

type Props = {
  model: Model;
  lines: PlaqueLines;
  captain?: string;
};

const props = withDefaults(defineProps<Props>(), {
  captain: undefined,
});

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

// Only ships of the model the plaque was made for: its class line and emblem
// come from the model, so on another one it would be a different plaque.
const { data: hangar, isLoading } = useHangar({
  q: { modelSlugIn: [props.model.slug] },
  perPage: "100",
});

const vehicles = computed(() => hangar.value?.items ?? []);

const vehicleLabel = (vehicle: Vehicle) =>
  [vehicle.name || vehicle.model.name, vehicle.serial]
    .filter(Boolean)
    .join(" · ");

const options = computed(() =>
  vehicles.value.map((vehicle) => ({
    value: vehicle.id,
    label: vehicle.dedication
      ? `${vehicleLabel(vehicle)} (${t("labels.plaqueTool.hasPlaque")})`
      : vehicleLabel(vehicle),
  })),
);

const selectedId = ref<string>();

// A single ship needs no choosing.
watch(
  vehicles,
  (list) => {
    if (!selectedId.value && list.length === 1) {
      selectedId.value = list[0].id;
    }
  },
  { immediate: true },
);

const selected = computed(() =>
  vehicles.value.find((vehicle) => vehicle.id === selectedId.value),
);

// The plaque as the picked ship will carry it: its own name and registry, the
// tool's lines.
const attached = computed<Vehicle | undefined>(() =>
  selected.value ? { ...selected.value, ...props.lines } : undefined,
);

const capture = ref<InstanceType<typeof PlaqueCapture>>();

const mutation = useUpdateVehicle();
const { invalidateHangarQueries, invalidateVehiclePage } =
  useVehicleMutations();

const { capturing, upload } = usePlaqueImageUpload((signedId) =>
  mutation.mutateAsync({
    id: selectedId.value!,
    data: { plaqueImage: signedId },
  }),
);

const saving = computed(() => mutation.isPending.value || capturing.value);

const save = async () => {
  if (!selected.value || saving.value) {
    return;
  }

  try {
    const vehicle = await mutation.mutateAsync({
      id: selected.value.id,
      data: { ...props.lines },
    });

    await upload(capture.value?.plaque());

    void invalidateHangarQueries();
    void invalidateVehiclePage(vehicle);

    displaySuccess({
      text: t("messages.plaqueTool.attached", {
        vehicle: vehicleLabel(vehicle),
      }),
    });
    comlink.emit("close-modal");
  } catch {
    displayAlert({ text: t("messages.vehiclePlaque.failure") });
  }
};
</script>

<template>
  <Modal :title="t('headlines.plaqueTool.attach')">
    <Loader v-if="isLoading" :loading="isLoading" />
    <p
      v-else-if="!vehicles.length"
      class="text-muted"
      data-test="plaque-attach-empty"
    >
      {{ t("texts.plaqueTool.noShips", { model: model.name }) }}
    </p>
    <template v-else>
      <p>{{ t("texts.plaqueTool.attachIntro") }}</p>
      <RadioList
        v-model="selectedId"
        name="plaqueVehicle"
        :label="t('labels.plaqueTool.vehicle')"
        :options="options"
        :inline="false"
        data-test="plaque-attach-vehicles"
      />
    </template>

    <PlaqueCapture v-if="attached" ref="capture" :vehicle="attached" :captain />

    <template #footer>
      <Btn
        :disabled="!selected"
        :loading="saving"
        :confirm="
          selected?.dedication
            ? t('messages.plaqueTool.replaceConfirm')
            : undefined
        "
        data-test="plaque-attach-save"
        @click="save"
      >
        {{ t("actions.plaqueTool.attach") }}
      </Btn>
    </template>
  </Modal>
</template>
