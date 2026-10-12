<script lang="ts">
export default {
  name: "VehiclePublicLogModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Markdown from "@/shared/components/Markdown/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import ListSkeleton from "@/shared/components/ListSkeleton/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { usePublicHangarShare } from "@/frontend/composables/usePublicHangarShare";
import {
  type VehiclePublic,
  usePublicVehicleLogEntries,
} from "@/services/fyApi";

type Props = {
  vehicle: VehiclePublic;
  username: string;
};

const props = defineProps<Props>();

const { t, l } = useI18n();
const { shareQuery } = usePublicHangarShare();

const { data: logEntries, isLoading } = usePublicVehicleLogEntries(
  () => props.username,
  () => props.vehicle.id,
  shareQuery,
);

const title = computed(() =>
  t("headlines.vehicleLog.public", {
    vehicle: props.vehicle.name || props.vehicle.model.name,
  }),
);
</script>

<template>
  <Modal :title="title">
    <ListSkeleton v-if="isLoading" />

    <Empty
      v-else-if="!logEntries?.length"
      :name="t('labels.vehicleLog.entries')"
      hide-actions
    >
      <template #info>
        <p>{{ t("texts.vehicleLog.publicEmpty") }}</p>
      </template>
    </Empty>

    <ol v-else class="public-vehicle-log">
      <li
        v-for="entry in logEntries"
        :key="entry.id"
        class="public-vehicle-log__entry"
        data-test="public-vehicle-log-entry"
      >
        <h3 class="public-vehicle-log__title">{{ entry.title }}</h3>
        <time :datetime="entry.loggedAt" class="public-vehicle-log__date">
          {{ l(entry.loggedAt, "datetime.formats.dateTimeZone") }}
        </time>
        <Markdown
          v-if="entry.body"
          :source="entry.body"
          class="public-vehicle-log__body"
        />
      </li>
    </ol>
  </Modal>
</template>

<style lang="scss" scoped>
.public-vehicle-log {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin: 0;
  padding: 0;
  list-style: none;

  &__entry {
    padding-bottom: 20px;
    border-bottom: 1px solid var(--color-edge-soft);

    &:last-child {
      padding-bottom: 0;
      border-bottom: none;
    }
  }

  &__title {
    margin: 0;
    font-size: 1.1rem;
    overflow-wrap: anywhere;
  }

  &__date {
    color: var(--color-text-dim);
    font-size: 0.85rem;
  }

  &__body {
    margin-top: 10px;
  }
}
</style>
