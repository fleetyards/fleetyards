<script lang="ts">
export default {
  name: "FleetDiscordSettingsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetNotificationSetting,
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

const hydrate = (s: FleetNotificationSetting) => {
  discordGuildId.value = s.discordGuildId ?? "";
  discordChannelId.value = s.discordChannelId ?? "";
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
  installUrl?: string | null;
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
        :size="BtnSizesEnum.SMALL"
        inline
        variant="link"
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
  gap: 0.5rem;
  flex-wrap: wrap;
  margin: 0.4rem 0 0.8rem;
  font-size: 0.95rem;

  i {
    color: var(--accent, #4aa);
  }

  a {
    text-decoration: underline;
  }
}
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
