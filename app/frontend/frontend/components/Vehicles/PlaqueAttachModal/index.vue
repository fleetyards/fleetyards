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
import { useHangarStore } from "@/frontend/stores/hangar";
import { gameSerial } from "@/frontend/utils/vehicleSegment";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useHangar,
  useUpdateVehicle,
  useWishlist,
  type Model,
  type Vehicle,
} from "@/services/fyApi";

type Props = {
  model: Model;
  lines: PlaqueLines;
  captain?: string;
  // The name and registry written in the tool, for a ship added from here.
  name?: string;
  serial?: string;
};

const props = withDefaults(defineProps<Props>(), {
  captain: undefined,
  name: undefined,
  serial: undefined,
});

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

// Only ships of the model the plaque was made for: its class line and emblem
// come from the model, so on another one it would be a different plaque. A
// ship hidden from the hangar list, or one still on the wishlist, is still the
// user's to dedicate.
const hangarQuery = useHangar({
  q: { modelSlugIn: [props.model.slug], hiddenByUserEq: "true" },
  perPage: "100",
});

const wishlistQuery = useWishlist({
  q: { modelSlugIn: [props.model.slug] },
  perPage: "100",
});

const isLoading = computed(
  () => hangarQuery.isLoading.value || wishlistQuery.isLoading.value,
);

const isError = computed(
  () => hangarQuery.isError.value || wishlistQuery.isError.value,
);

const refetch = () => {
  void hangarQuery.refetch();
  void wishlistQuery.refetch();
};

const vehicles = computed(() => [
  ...(hangarQuery.data.value?.items ?? []),
  ...(wishlistQuery.data.value?.items ?? []),
]);

const vehicleLabel = (vehicle: Vehicle) =>
  [vehicle.name || vehicle.model.name, vehicle.serial]
    .filter(Boolean)
    .join(" · ");

const options = computed(() =>
  vehicles.value.map((vehicle) => {
    const notes = [
      vehicle.wanted ? t("labels.wishlist") : undefined,
      vehicle.dedication ? t("labels.plaqueTool.hasPlaque") : undefined,
    ].filter(Boolean);

    return {
      value: vehicle.id,
      label: notes.length
        ? `${vehicleLabel(vehicle)} (${notes.join(", ")})`
        : vehicleLabel(vehicle),
    };
  }),
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

// A ship added from here, before the hangar list knows it.
const created = ref<Vehicle>();

// The plaque as the ship will carry it: its own name and registry, the tool's
// lines.
const attached = computed<Vehicle | undefined>(() => {
  const target = created.value ?? selected.value;

  return target ? { ...target, ...props.lines } : undefined;
});

const capture = ref<InstanceType<typeof PlaqueCapture>>();

const mutation = useUpdateVehicle();
const { invalidateHangarQueries, invalidateVehiclePage, useCreateMutation } =
  useVehicleMutations();
const createMutation = useCreateMutation();
const hangarStore = useHangarStore();

const { capturing, upload } = usePlaqueImageUpload((signedId) =>
  mutation.mutateAsync({
    id: attached.value!.id,
    data: { plaqueImage: signedId },
  }),
);

// Held once a ship is added, so the button does not swap for the list's own
// while the hangar refetches mid-save.
const addsShip = computed(
  () =>
    !!created.value ||
    (!isLoading.value &&
      !isError.value &&
      !vehicles.value.length &&
      props.model.playerOwnable),
);

const saving = computed(
  () =>
    mutation.isPending.value ||
    createMutation.isPending.value ||
    capturing.value,
);

const attach = async (
  target: Vehicle,
  failure = t("messages.vehiclePlaque.failure"),
) => {
  try {
    const vehicle = await mutation.mutateAsync({
      id: target.id,
      data: { ...props.lines },
    });

    // The picture is drawn from the off-screen plaque, which needs a tick to
    // show a ship added a moment ago.
    await nextTick();
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
    displayAlert({ text: failure });
  }
};

const save = async () => {
  if (!selected.value || saving.value) {
    return;
  }

  await attach(selected.value);
};

// The plaque's name goes with the new ship; its registry only where it is one
// the game would print, as the hangar takes no other.
const createAndAttach = async () => {
  if (saving.value) {
    return;
  }

  // A ship added on an earlier try, whose plaque did not save, is not added a
  // second time.
  if (created.value) {
    await attach(created.value, t("messages.plaqueTool.addedWithoutPlaque"));
    return;
  }

  try {
    created.value = await createMutation.mutateAsync({
      data: {
        modelId: props.model.id,
        name: props.name || null,
        serial: gameSerial(props.serial) ?? null,
      },
    });
  } catch {
    displayAlert({ text: t("messages.plaqueTool.createFailure") });
    return;
  }

  hangarStore.add(props.model.slug);

  await attach(created.value, t("messages.plaqueTool.addedWithoutPlaque"));
};
</script>

<template>
  <Modal :title="t('headlines.plaqueTool.attach')">
    <Loader v-if="isLoading" :loading="isLoading" />
    <div v-else-if="isError" data-test="plaque-attach-error">
      <p class="text-muted">{{ t("messages.plaqueTool.hangarFailure") }}</p>
      <Btn @click="refetch()">{{ t("actions.retry") }}</Btn>
    </div>
    <div v-else-if="!vehicles.length" data-test="plaque-attach-empty">
      <p class="text-muted">
        {{ t("texts.plaqueTool.noShips", { model: model.name }) }}
      </p>
      <p v-if="model.playerOwnable">
        {{ t("texts.plaqueTool.addShip", { model: model.name }) }}
      </p>
    </div>
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
        v-if="addsShip"
        :loading="saving"
        data-test="plaque-attach-create"
        @click="createAndAttach"
      >
        <template v-if="created">{{ t("actions.plaqueTool.attach") }}</template>
        <template v-else>
          <i class="fa-duotone fa-plus" />
          {{ t("actions.plaqueTool.addShip", { model: model.name }) }}
        </template>
      </Btn>
      <Btn
        v-else
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
