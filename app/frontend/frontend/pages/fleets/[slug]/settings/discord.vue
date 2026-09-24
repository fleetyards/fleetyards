<script lang="ts">
export default {
  name: "FleetDiscordSettingsPage",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import DiscordChannelSelect from "@/frontend/components/Fleets/DiscordChannelSelect/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetNotificationSetting,
  fleetNotificationDiscordStatus,
  getFleetDiscordChannelsQueryKey,
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

const { t, tExists } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const fleetSlug = computed(() => props.fleet.slug);

const { data: setting, refetch } = useFleetNotificationSetting(fleetSlug);

const updateMutation = useUpdateFleetNotificationSetting();

const queryClient = useQueryClient();

const discordGuildId = ref<string>("");
const discordChannelId = ref<string>("");
const discordAnnouncementChannelId = ref<string | null>(null);
const discordWebhookUrl = ref<string>("");

const hydrate = (s: FleetNotificationSetting) => {
  discordGuildId.value = s.discordGuildId ?? "";
  discordChannelId.value = s.discordChannelId ?? "";
  discordAnnouncementChannelId.value = s.discordAnnouncementChannelId ?? null;
  discordWebhookUrl.value = "";
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
      discordAnnouncementChannelId: discordAnnouncementChannelId.value || null,
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
    // A different server has different channels.
    void queryClient.invalidateQueries({
      queryKey: getFleetDiscordChannelsQueryKey(props.fleet.slug),
    });
    void fetchStatus();
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
  installUrl?: string | null;
  postingOk?: boolean;
  postingCode?: string;
  postingDetail?: string;
};

const discordStatus = ref<DiscordStatus | null>(null);
const probing = ref(false);

const fetchStatus = async () => {
  try {
    discordStatus.value = (await fleetNotificationDiscordStatus(
      props.fleet.slug,
    )) as DiscordStatus;
  } catch {
    discordStatus.value = {
      ok: false,
      code: "request_failed",
      message: "Could not reach Fleetyards backend",
    };
  }
};

onMounted(fetchStatus);

const probeDiscord = async () => {
  probing.value = true;
  try {
    await fetchStatus();
  } finally {
    probing.value = false;
  }
};

const installUrl = computed(() => discordStatus.value?.installUrl ?? null);

const postingProblem = computed(() => {
  const status = discordStatus.value;
  if (!status?.postingCode || status.postingOk) return null;

  const key = `labels.fleet.discord.postingCodes.${status.postingCode}`;
  return tExists(key)
    ? t(key, { names: status.postingDetail ?? "" })
    : t(`labels.fleet.discord.statusCodes.${status.postingCode}`);
});
</script>

<template>
  <form id="fleet-discord-form" @submit.prevent="save">
    <p class="text-muted">
      {{ t("labels.fleet.discord.hint") }}
    </p>

    <p v-if="installUrl" class="discord-install">
      <i class="fa-brands fa-discord" />
      <a :href="installUrl" target="_blank" rel="noopener">
        {{ t("actions.fleet.discord.installBot") }}
      </a>
      <span class="text-muted small">
        {{ t("labels.fleet.discord.installBotHint") }}
      </span>
    </p>

    <div class="discord-status-row">
      <Btn
        :size="BtnSizesEnum.SM"
        variant="bare"
        :loading="probing"
        @click="probeDiscord"
      >
        <i class="fa-light fa-plug" />
        {{ t("actions.fleet.discord.test") }}
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
            t("labels.fleet.discord.statusOk", {
              name: discordStatus.guildName,
            })
          }}
        </span>
        <span v-else>
          {{
            discordStatus.code
              ? t(`labels.fleet.discord.statusCodes.${discordStatus.code}`)
              : discordStatus.message
          }}
        </span>
      </span>
      <span
        v-if="postingProblem"
        class="discord-status discord-status--err"
        data-test="posting-problem"
      >
        <i class="fa-light fa-triangle-exclamation" />
        <span>{{ postingProblem }}</span>
      </span>
    </div>

    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="discordGuildId"
          name="discordGuildId"
          icon="fa-brands fa-discord"
          translation-key="fleet.discord.guildId"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="discordChannelId"
          name="discordChannelId"
          icon="fa-brands fa-discord"
          translation-key="fleet.discord.channelId"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-6">
        <DiscordChannelSelect
          v-model="discordAnnouncementChannelId"
          :fleet-slug="props.fleet.slug"
          name="discordAnnouncementChannelId"
          :label="t('labels.fleet.discord.announcementChannel')"
          :info="t('labels.fleet.discord.announcementChannelHint')"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12">
        <FormInput
          v-model="discordWebhookUrl"
          name="discordWebhookUrl"
          icon="fa-brands fa-discord"
          translation-key="fleet.discord.webhookUrl"
          :placeholder="
            setting?.discordWebhookConfigured
              ? t('placeholders.fleet.discord.webhookConfigured')
              : t('placeholders.fleet.discord.webhookUrl')
          "
        />
      </div>
    </div>

    <FormActions
      form-id="fleet-discord-form"
      :submitting="submitting"
      @cancel="reset"
    />
  </form>
</template>

<style lang="scss" scoped>
.discord-install {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  margin: 6px 0 13px;
  font-size: 15px;

  i {
    color: var(--color-primary, #428bca);
  }

  a {
    text-decoration: underline;
  }
}
.discord-status-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  margin: 8px 0 16px;
}
.discord-status {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
}
.discord-status--ok {
  color: var(--color-success, #5cb85c);
}
.discord-status--err {
  color: var(--color-warning, #fa6800);
}
</style>
