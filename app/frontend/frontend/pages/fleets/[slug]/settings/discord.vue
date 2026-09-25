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
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import { useI18nStore } from "@/shared/stores/i18n";
import {
  type FilterOption,
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
const discordOfficersChannelId = ref<string | null>(null);
const discordDigestWeekday = ref<string | null>(null);
const discordDigestTime = ref<string>("");

// The day and time are read in the zone they were picked in, which is this
// browser's -- the same way an event takes its own.
const browserTimezone = () =>
  Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";

// What is saved, so a save by somebody elsewhere that leaves the day and time
// alone does not move the digest into their zone.
const savedDigest = ref<{
  weekday: string | null;
  time: string;
  timezone: string | null;
}>({ weekday: null, time: "", timezone: null });

const digestTimezone = computed(() => {
  const saved = savedDigest.value;
  const unchanged =
    discordDigestWeekday.value === saved.weekday &&
    discordDigestTime.value === saved.time;

  return unchanged && saved.timezone ? saved.timezone : browserTimezone();
});
const discordWebhookUrl = ref<string>("");

const hydrate = (s: FleetNotificationSetting) => {
  discordGuildId.value = s.discordGuildId ?? "";
  discordChannelId.value = s.discordChannelId ?? "";
  discordAnnouncementChannelId.value = s.discordAnnouncementChannelId ?? null;
  discordOfficersChannelId.value = s.discordOfficersChannelId ?? null;
  discordDigestWeekday.value =
    s.discordDigestWeekday === null || s.discordDigestWeekday === undefined
      ? null
      : String(s.discordDigestWeekday);
  discordDigestTime.value = s.discordDigestTime ?? "";
  savedDigest.value = {
    weekday: discordDigestWeekday.value,
    time: discordDigestTime.value,
    timezone: s.discordDigestTimezone ?? null,
  };
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

const i18nStore = useI18nStore();

// A digest needs a time, so picking a day starts from an evening rather than
// from a save that fails.
watch(discordDigestWeekday, (weekday) => {
  if (weekday && !discordDigestTime.value) discordDigestTime.value = "18:00";
});

/*
 * Monday first, the way most of the fleets reading this count a week, while
 * the values stay Ruby's Sunday-first `wday`. The names come from the browser
 * rather than seven new strings in every locale: 2024-01-07 was a Sunday.
 */
const weekdayOptions = computed<FilterOption[]>(() => {
  const format = new Intl.DateTimeFormat(i18nStore.locale, {
    weekday: "long",
    timeZone: "UTC",
  });

  return [1, 2, 3, 4, 5, 6, 0].map((wday) => ({
    value: String(wday),
    label: format.format(new Date(Date.UTC(2024, 0, 7 + wday))),
  }));
});

const save = async () => {
  submitting.value = true;
  try {
    const payload: Record<string, unknown> = {
      discordGuildId: discordGuildId.value || null,
      discordChannelId: discordChannelId.value || null,
      discordAnnouncementChannelId: discordAnnouncementChannelId.value || null,
      discordOfficersChannelId: discordOfficersChannelId.value || null,
      discordDigestWeekday: discordDigestWeekday.value
        ? Number(discordDigestWeekday.value)
        : null,
      discordDigestTime: discordDigestWeekday.value
        ? discordDigestTime.value || null
        : null,
      discordDigestTimezone: discordDigestWeekday.value
        ? digestTimezone.value
        : null,
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
      <div class="col-12 col-md-6">
        <DiscordChannelSelect
          v-model="discordOfficersChannelId"
          :fleet-slug="props.fleet.slug"
          name="discordOfficersChannelId"
          :label="t('labels.fleet.discord.officersChannel')"
          :info="t('labels.fleet.discord.officersChannelHint')"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-6">
        <BaseSelect
          v-model="discordDigestWeekday"
          :options="weekdayOptions"
          name="discordDigestWeekday"
          :label="t('labels.fleet.discord.digestWeekday')"
          :info="t('labels.fleet.discord.digestWeekdayHint')"
          :searchable="false"
          unsorted
        />
      </div>
      <div v-if="discordDigestWeekday" class="col-12 col-md-6">
        <FormInput
          v-model="discordDigestTime"
          name="discordDigestTime"
          :type="InputTypesEnum.TIME"
          :step="900"
          :label="t('labels.fleet.discord.digestTime')"
          :info="
            t('labels.fleet.discord.digestTimeHint', {
              timezone: digestTimezone,
            })
          "
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
