<script lang="ts">
export default {
  name: "HangarVehicleLogPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import Markdown from "@/shared/components/Markdown/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import ListSkeleton from "@/shared/components/ListSkeleton/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { useQueryClient } from "@tanstack/vue-query";
import {
  type Vehicle,
  type VehicleLogEntry,
  useVehicleLogEntries,
  useDestroyVehicleLogEntry,
  useUpdateVehicle,
  getVehicleLogEntriesQueryKey,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t, l } = useI18n();
const comlink = useComlink();
const queryClient = useQueryClient();
const { displayConfirm, displayAlert } = useAppNotifications();
const { invalidateVehiclePage } = useVehicleMutations();

const vehicleId = computed(() => props.vehicle.id);

const { data: logEntries, isLoading } = useVehicleLogEntries(vehicleId);

const entries = computed<VehicleLogEntry[]>(() => logEntries.value || []);

const openEntryModal = (logEntry?: VehicleLogEntry) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/LogEntryModal/index.vue"),
    props: {
      // The switch below saves on its own, so the page's vehicle can still
      // carry the old default when a new entry is started.
      vehicle: {
        ...props.vehicle,
        logEntriesPublicByDefault: publicByDefault.value,
      },
      logEntry,
    },
  });
};

const destroyMutation = useDestroyVehicleLogEntry({
  mutation: {
    onSettled: () =>
      queryClient.invalidateQueries({
        queryKey: getVehicleLogEntriesQueryKey(props.vehicle.id),
      }),
  },
});

const destroy = (logEntry: VehicleLogEntry) => {
  displayConfirm({
    text: t("messages.confirm.vehicleLog.destroy"),
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync({ vehicleId: props.vehicle.id, id: logEntry.id })
        .catch(() => {
          displayAlert({ text: t("messages.vehicleLog.destroy.failure") });
        });
    },
  });
};

// The public hangar lists only bought ships, so a wishlist ship's entries are
// never shown there, public or not.
const publiclyListed = computed(
  () => props.vehicle.public && !props.vehicle.wanted,
);

// Only new entries follow it; the ones already written keep their own switch.
const publicByDefault = ref(props.vehicle.logEntriesPublicByDefault);

watch(
  () => props.vehicle.logEntriesPublicByDefault,
  (value) => {
    publicByDefault.value = value;
  },
);

const updateVehicle = useUpdateVehicle();

const updatePublicByDefault = async (value: boolean) => {
  publicByDefault.value = value;

  await updateVehicle
    .mutateAsync({
      id: props.vehicle.id,
      data: { logEntriesPublicByDefault: value },
    })
    .then((updatedVehicle) => invalidateVehiclePage(updatedVehicle))
    .catch(() => {
      publicByDefault.value = !value;
      displayAlert({ text: t("messages.vehicleLog.defaultUpdate.failure") });
    });
};
</script>

<template>
  <div class="vehicle-log">
    <div class="vehicle-log__toolbar">
      <Btn data-test="vehicle-log-add" @click="openEntryModal()">
        <i class="fa-duotone fa-plus" />
        {{ t("actions.vehicleLog.add") }}
      </Btn>
      <FormToggle
        :model-value="publicByDefault"
        name="logEntriesPublicByDefault"
        :label="t('labels.vehicleLog.publicByDefault')"
        :disabled="updateVehicle.isPending.value"
        data-test="vehicle-log-public-default"
        @update:model-value="updatePublicByDefault"
      />
    </div>

    <p class="vehicle-log__hint">
      {{
        publiclyListed
          ? t("texts.vehicleLog.visibility")
          : t("texts.vehicleLog.visibilityHidden")
      }}
    </p>

    <ListSkeleton v-if="isLoading" />

    <Empty
      v-else-if="!entries.length"
      :variant="EmptyVariantsEnum.BOX"
      :name="t('labels.vehicleLog.entries')"
      hide-actions
    >
      <template #info>
        <p>{{ t("texts.vehicleLog.empty") }}</p>
      </template>
    </Empty>

    <ol v-else class="vehicle-log__entries">
      <li
        v-for="entry in entries"
        :key="entry.id"
        class="vehicle-log__entry"
        data-test="vehicle-log-entry"
      >
        <div class="vehicle-log__entry-header">
          <div class="vehicle-log__entry-heading">
            <h3 class="vehicle-log__entry-title">{{ entry.title }}</h3>
            <time :datetime="entry.loggedAt" class="vehicle-log__entry-date">
              {{ l(entry.loggedAt, "datetime.formats.dateTimeZone") }}
            </time>
          </div>
          <Pill v-if="entry.public" data-test="vehicle-log-entry-public">
            {{ t("labels.vehicleLog.publicShort") }}
          </Pill>
          <div class="vehicle-log__entry-actions">
            <Btn
              :aria-label="t('actions.edit')"
              data-test="vehicle-log-entry-edit"
              @click="openEntryModal(entry)"
            >
              <i class="fa fa-pencil" />
            </Btn>
            <Btn
              :aria-label="t('actions.remove')"
              :tone="BtnTonesEnum.DANGER"
              data-test="vehicle-log-entry-remove"
              @click="destroy(entry)"
            >
              <i class="fa-light fa-trash" />
            </Btn>
          </div>
        </div>
        <Markdown
          v-if="entry.body"
          :source="entry.body"
          class="vehicle-log__entry-body"
        />
      </li>
    </ol>
  </div>
</template>

<style lang="scss" scoped>
.vehicle-log {
  &__toolbar {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    margin-bottom: 10px;
  }

  &__hint {
    color: var(--color-text-dim);
    font-size: 0.85rem;
  }

  &__entries {
    display: flex;
    flex-direction: column;
    gap: 20px;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  &__entry {
    padding-bottom: 20px;
    border-bottom: 1px solid var(--color-edge-soft);

    &:last-child {
      border-bottom: none;
    }
  }

  &__entry-header {
    display: flex;
    align-items: flex-start;
    gap: 10px;
  }

  &__entry-heading {
    display: flex;
    flex: 1;
    flex-direction: column;
    gap: 2px;
    min-width: 0;
  }

  &__entry-title {
    margin: 0;
    font-size: 1.1rem;
    overflow-wrap: anywhere;
  }

  &__entry-date {
    color: var(--color-text-dim);
    font-size: 0.85rem;
  }

  &__entry-actions {
    display: flex;
    gap: 5px;
  }

  &__entry-body {
    margin-top: 10px;
  }
}
</style>
