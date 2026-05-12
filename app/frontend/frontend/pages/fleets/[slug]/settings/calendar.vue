<script lang="ts">
export default {
  name: "FleetCalendarSettingsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Loader from "@/shared/components/Loader/index.vue";
import {
  type Fleet,
  type FleetMember,
  useFleetCalendarSubscription,
  useCreateFleetCalendarSubscription,
  useRotateFleetCalendarSubscription,
  useDestroyFleetCalendarSubscription,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const fleetSlug = computed(() => props.fleet.slug);

const { data: subscription, refetch, isPending } =
  useFleetCalendarSubscription(fleetSlug);

const createMutation = useCreateFleetCalendarSubscription();
const rotateMutation = useRotateFleetCalendarSubscription();
const destroyMutation = useDestroyFleetCalendarSubscription();

const enabled = computed(() => subscription.value?.enabled === true);
const feedUrl = computed(() => subscription.value?.feedUrl ?? "");

const enable = async () => {
  try {
    await createMutation.mutateAsync({ fleetSlug: props.fleet.slug });
    await refetch();
    displaySuccess({
      text: t("messages.fleet.calendarSubscription.enable.success"),
    });
  } catch {
    displayAlert({
      text: t("messages.fleet.calendarSubscription.enable.failure"),
    });
  }
};

const rotate = () => {
  displayConfirm({
    text: t("messages.fleet.calendarSubscription.rotate.confirm"),
    confirmText: t("actions.fleet.calendarSubscription.rotate"),
    onConfirm: async () => {
      try {
        await rotateMutation.mutateAsync({ fleetSlug: props.fleet.slug });
        await refetch();
        displaySuccess({
          text: t("messages.fleet.calendarSubscription.rotate.success"),
        });
      } catch {
        displayAlert({
          text: t("messages.fleet.calendarSubscription.rotate.failure"),
        });
      }
    },
  });
};

const disable = () => {
  displayConfirm({
    text: t("messages.fleet.calendarSubscription.disable.confirm"),
    confirmText: t("actions.fleet.calendarSubscription.disable"),
    onConfirm: async () => {
      try {
        await destroyMutation.mutateAsync({ fleetSlug: props.fleet.slug });
        await refetch();
        displaySuccess({
          text: t("messages.fleet.calendarSubscription.disable.success"),
        });
      } catch {
        displayAlert({
          text: t("messages.fleet.calendarSubscription.disable.failure"),
        });
      }
    },
  });
};

const copyFeedUrl = async () => {
  if (!feedUrl.value) return;
  try {
    await navigator.clipboard.writeText(feedUrl.value);
    displaySuccess({
      text: t("messages.fleet.calendarSubscription.copy.success"),
    });
  } catch {
    displayAlert({
      text: t("messages.fleet.calendarSubscription.copy.failure"),
    });
  }
};
</script>

<template>
  <Loader :loading="isPending" />

  <p class="text-muted">
    {{ t("labels.fleet.calendarSubscription.intro") }}
  </p>

  <template v-if="!enabled">
    <Btn
      :size="BtnSizesEnum.SMALL"
      :loading="createMutation.isPending.value"
      @click="enable"
    >
      <i class="fa-light fa-calendar-plus" />
      <span>{{ t("actions.fleet.calendarSubscription.enable") }}</span>
    </Btn>
  </template>

  <template v-else>
    <div class="calendar-settings__url">
      <input
        type="text"
        readonly
        :value="feedUrl"
        class="calendar-settings__field"
        @focus="($event.target as HTMLInputElement).select()"
      />
      <Btn :size="BtnSizesEnum.SMALL" inline @click="copyFeedUrl">
        <i class="fa-light fa-copy" />
        <span>{{ t("actions.copy") }}</span>
      </Btn>
    </div>

    <p class="text-muted small">
      {{ t("labels.fleet.calendarSubscription.howTo") }}
    </p>

    <hr />

    <div class="calendar-settings__actions">
      <Btn
        :size="BtnSizesEnum.SMALL"
        :loading="rotateMutation.isPending.value"
        inline
        @click="rotate"
      >
        <i class="fa-light fa-arrows-rotate" />
        <span>{{ t("actions.fleet.calendarSubscription.rotate") }}</span>
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.DANGER"
        :loading="destroyMutation.isPending.value"
        inline
        @click="disable"
      >
        <i class="fa-light fa-circle-xmark" />
        <span>{{ t("actions.fleet.calendarSubscription.disable") }}</span>
      </Btn>
    </div>
  </template>
</template>

<style lang="scss" scoped>
.calendar-settings__url {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0.5rem 0;
}
.calendar-settings__field {
  flex: 1;
  padding: 0.4rem 0.6rem;
  font-family: monospace;
  font-size: 0.85rem;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 3px;
  color: inherit;
}
.calendar-settings__actions {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}
.small {
  font-size: 0.8rem;
}
</style>
