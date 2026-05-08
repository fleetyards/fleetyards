<script lang="ts">
export default {
  name: "FleetNotificationSettingsPage",
};
</script>

<script lang="ts" setup>
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetNotificationSetting,
  FleetNotificationSettingEnabledInAppEventsItem,
  useFleetNotificationSetting,
  useUpdateFleetNotificationSetting,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const fleetSlug = computed(() => props.fleet.slug);

const { data: setting, refetch } = useFleetNotificationSetting(fleetSlug);

const updateMutation = useUpdateFleetNotificationSetting();

const enabledInApp = ref<Record<string, boolean>>({});

const inAppEvents = computed(() =>
  Object.values(FleetNotificationSettingEnabledInAppEventsItem),
);

const hydrate = (s: FleetNotificationSetting) => {
  enabledInApp.value = inAppEvents.value.reduce<Record<string, boolean>>(
    (acc, name) => {
      acc[name] = s.enabledInAppEvents.includes(name);
      return acc;
    },
    {},
  );
};

watch(
  setting,
  (s) => {
    if (s) hydrate(s);
  },
  { immediate: true },
);

const submitting = ref(false);

const save = async () => {
  submitting.value = true;
  try {
    await updateMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      data: {
        enabledInAppEvents: Object.entries(enabledInApp.value)
          .filter(([, on]) => on)
          .map(([k]) => k),
      },
    });
    displaySuccess({ text: t("messages.fleets.notifications.update.success") });
    void refetch();
  } catch {
    displayAlert({ text: t("messages.fleets.notifications.update.failure") });
  } finally {
    submitting.value = false;
  }
};

const reset = () => {
  if (setting.value) hydrate(setting.value);
};
</script>

<template>
  <form id="fleet-notifications-form" @submit.prevent="save">
    <p class="text-muted">
      {{ t("labels.fleet.notifications.inAppHint") }}
    </p>

    <div class="row">
      <div
        v-for="name in inAppEvents"
        :key="`in-app-${name}`"
        class="col-12 col-md-6"
      >
        <FormToggle
          v-model="enabledInApp[name]"
          :name="`in-app-${name}`"
          :label="t(`labels.fleet.notifications.events.${name}`)"
        />
      </div>
    </div>

    <FormActions
      form-id="fleet-notifications-form"
      :submitting="submitting"
      @cancel="reset"
    />
  </form>
</template>
