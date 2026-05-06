<script lang="ts">
export default {
  name: "FleetNotificationSettingsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetNotificationSetting,
  FleetNotificationSettingEnabledInAppEventsItem,
  FleetNotificationSettingEnabledDiscordEventsItem,
  fleetNotificationDiscordStatus,
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

type DiscordStatus = {
  ok: boolean;
  code?: string;
  message?: string;
  guildId?: string;
  guildName?: string;
};

const discordStatus = ref<DiscordStatus | null>(null);
const probing = ref(false);

const probeDiscord = async () => {
  probing.value = true;
  try {
    const result = (await fleetNotificationDiscordStatus(
      props.fleet.slug,
    )) as DiscordStatus;
    discordStatus.value = result;
  } catch {
    discordStatus.value = {
      ok: false,
      code: "request_failed",
      message: "Could not reach Fleetyards backend",
    };
  } finally {
    probing.value = false;
  }
};
</script>

<template>
  <form id="fleet-notifications-form" @submit.prevent="save">
    <h3>{{ t("labels.fleet.notifications.inAppHeading") }}</h3>
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

    <hr />

    <h3>{{ t("labels.fleet.notifications.discordHeading") }}</h3>
    <p class="text-muted">
      {{ t("labels.fleet.notifications.discordHint") }}
    </p>

    <div class="discord-status-row">
      <Btn
        :size="BtnSizesEnum.SMALL"
        inline
        variant="link"
        :loading="probing"
        @click="probeDiscord"
      >
        <i class="fa-light fa-plug" />
        {{ t("actions.fleet.notifications.testDiscord") }}
      </Btn>
      <span
        v-if="discordStatus"
        class="discord-status"
        :class="discordStatus.ok ? 'discord-status--ok' : 'discord-status--err'"
      >
        <i
          class="fa-light"
          :class="
            discordStatus.ok ? 'fa-circle-check' : 'fa-triangle-exclamation'
          "
        />
        <span v-if="discordStatus.ok">
          {{
            t("labels.fleet.notifications.discordStatusOk", {
              name: discordStatus.guildName,
            })
          }}
        </span>
        <span v-else>
          {{
            discordStatus.code
              ? t(
                  `labels.fleet.notifications.discordStatusCodes.${discordStatus.code}`,
                )
              : discordStatus.message
          }}
        </span>
      </span>
    </div>

    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="discordGuildId"
          name="discordGuildId"
          icon="fa-brands fa-discord"
          translation-key="fleet.notifications.discordGuildId"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="discordChannelId"
          name="discordChannelId"
          icon="fa-brands fa-discord"
          translation-key="fleet.notifications.discordChannelId"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12">
        <FormInput
          v-model="discordWebhookUrl"
          name="discordWebhookUrl"
          icon="fa-brands fa-discord"
          translation-key="fleet.notifications.discordWebhookUrl"
          :placeholder="
            setting?.discordWebhookConfigured
              ? t('placeholders.fleet.notifications.discordWebhookConfigured')
              : t('placeholders.fleet.notifications.discordWebhookUrl')
          "
        />
      </div>
    </div>

    <p class="text-muted">
      {{ t("labels.fleet.notifications.discordEventsHint") }}
    </p>

    <div class="row">
      <div
        v-for="name in discordEvents"
        :key="`discord-${name}`"
        class="col-12 col-md-6"
      >
        <FormToggle
          v-model="enabledDiscord[name]"
          :name="`discord-${name}`"
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

<style lang="scss" scoped>
.discord-status-row {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  flex-wrap: wrap;
  margin: 0.5rem 0 1rem;
}
.discord-status {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  font-size: 0.85rem;
}
.discord-status--ok {
  color: var(--success, #4caf50);
}
.discord-status--err {
  color: var(--warning, #ff9800);
}
</style>
