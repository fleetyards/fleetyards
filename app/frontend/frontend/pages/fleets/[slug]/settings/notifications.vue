<script lang="ts">
export default {
  name: "FleetNotificationSettingsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetNotificationSetting,
  FleetNotificationSettingEnabledInAppEventsItem,
  FleetNotificationSettingEnabledDiscordEventsItem,
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

const discordGuildId = ref<string>("");
const discordChannelId = ref<string>("");
const discordWebhookUrl = ref<string>("");
const enabledInApp = ref<Record<string, boolean>>({});
const enabledDiscord = ref<Record<string, boolean>>({});

const inAppEvents = computed(() =>
  Object.values(FleetNotificationSettingEnabledInAppEventsItem),
);
const discordEvents = computed(() =>
  Object.values(FleetNotificationSettingEnabledDiscordEventsItem),
);

const hydrate = (s: FleetNotificationSetting) => {
  discordGuildId.value = s.discordGuildId ?? "";
  discordChannelId.value = s.discordChannelId ?? "";
  discordWebhookUrl.value = "";
  enabledInApp.value = inAppEvents.value.reduce<Record<string, boolean>>(
    (acc, name) => {
      acc[name] = s.enabledInAppEvents.includes(name);
      return acc;
    },
    {},
  );
  enabledDiscord.value = discordEvents.value.reduce<Record<string, boolean>>(
    (acc, name) => {
      acc[name] = s.enabledDiscordEvents.includes(name);
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
    const payload: Record<string, unknown> = {
      discordGuildId: discordGuildId.value || null,
      discordChannelId: discordChannelId.value || null,
      enabledInAppEvents: Object.entries(enabledInApp.value)
        .filter(([, on]) => on)
        .map(([k]) => k),
      enabledDiscordEvents: Object.entries(enabledDiscord.value)
        .filter(([, on]) => on)
        .map(([k]) => k),
    };
    if (discordWebhookUrl.value !== "") {
      payload.discordWebhookUrl = discordWebhookUrl.value;
    }
    await updateMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      data: payload,
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
  <Heading size="hero" hero>
    {{ t("headlines.fleets.settings.notifications") }}
  </Heading>

  <form
    id="fleet-notifications-form"
    class="notification-settings"
    @submit.prevent="save"
  >
    <section class="notification-settings__section">
      <Heading size="lg">
        {{ t("headlines.fleets.settings.inAppNotifications") }}
      </Heading>
      <p class="text-muted">
        {{ t("labels.fleets.notifications.inAppHint") }}
      </p>
      <ul class="notification-settings__events">
        <li v-for="name in inAppEvents" :key="`in-app-${name}`">
          <FormToggle
            v-model="enabledInApp[name]"
            :name="`in-app-${name}`"
            :label="t(`labels.fleets.notifications.events.${name}`)"
          />
        </li>
      </ul>
    </section>

    <section class="notification-settings__section">
      <Heading size="lg">
        {{ t("headlines.fleets.settings.discord") }}
      </Heading>
      <p class="text-muted">
        {{ t("labels.fleets.notifications.discordHint") }}
      </p>

      <FormInput
        v-model="discordGuildId"
        name="discordGuildId"
        :label="t('labels.fleets.notifications.discordGuildId')"
        :placeholder="t('placeholders.fleets.notifications.discordGuildId')"
      />
      <FormInput
        v-model="discordChannelId"
        name="discordChannelId"
        :label="t('labels.fleets.notifications.discordChannelId')"
        :placeholder="t('placeholders.fleets.notifications.discordChannelId')"
      />
      <FormInput
        v-model="discordWebhookUrl"
        name="discordWebhookUrl"
        :label="t('labels.fleets.notifications.discordWebhookUrl')"
        :placeholder="
          setting?.discordWebhookConfigured
            ? t('placeholders.fleets.notifications.discordWebhookConfigured')
            : t('placeholders.fleets.notifications.discordWebhookUrl')
        "
      />

      <p class="text-muted small">
        {{ t("labels.fleets.notifications.discordEventsHint") }}
      </p>
      <ul class="notification-settings__events">
        <li v-for="name in discordEvents" :key="`discord-${name}`">
          <FormToggle
            v-model="enabledDiscord[name]"
            :name="`discord-${name}`"
            :label="t(`labels.fleets.notifications.events.${name}`)"
          />
        </li>
      </ul>
    </section>

    <FormActions
      form-id="fleet-notifications-form"
      :submitting="submitting"
      @cancel="reset"
    />
  </form>
</template>

<style lang="scss" scoped>
.notification-settings {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  max-width: 720px;
}
.notification-settings__section {
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
  padding: 1rem;
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.02);
}
.notification-settings__events {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}
.small {
  font-size: 0.85rem;
}
</style>
