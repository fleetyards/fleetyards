<script lang="ts">
export default {
  name: "FleetDiscordChannelSelect",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetDiscordConnectionCodeEnum,
  useFleetDiscordChannels,
  type FilterOption,
} from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  modelValue?: string | null;
  name: string;
  label: string;
  info?: string;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: null,
  info: undefined,
});

const emit = defineEmits<{ "update:modelValue": [value: string | null] }>();

const { t } = useI18n();

const { data: channels, isLoading } = useFleetDiscordChannels(
  computed(() => props.fleetSlug),
);

const connected = computed(
  () => channels.value?.code === FleetDiscordConnectionCodeEnum.OK,
);

/*
 * Only a guild that answered can say a channel is gone. While Discord is
 * unreachable the saved channel is kept as it is, not reported as deleted.
 */
const missing = computed(
  () =>
    connected.value &&
    !!props.modelValue &&
    !channels.value?.items.some((channel) => channel.id === props.modelValue),
);

const listed = computed(
  () =>
    !!props.modelValue &&
    !!channels.value?.items.some((channel) => channel.id === props.modelValue),
);

// Discord's own sidebar order, which the API already returns: a list sorted by
// name would split every category apart.
const options = computed<FilterOption[]>(() => {
  const items = (channels.value?.items ?? []).map((channel) => ({
    value: channel.id,
    label: channel.parentName
      ? `#${channel.name} (${channel.parentName})`
      : `#${channel.name}`,
  }));

  // The saved channel stays selectable, and so clearable, whatever Discord
  // says about it -- a server the bot was removed from would otherwise hold on
  // to a channel nobody can take off.
  if (props.modelValue && !listed.value) {
    items.unshift({
      value: props.modelValue,
      label: missing.value
        ? t("labels.fleet.discord.missingChannel")
        : `#${props.modelValue}`,
    });
  }

  return items;
});

const selected = computed({
  get: () => props.modelValue ?? null,
  set: (value: string | null) => emit("update:modelValue", value || null),
});
</script>

<template>
  <div class="discord-channel-select">
    <BaseSelect
      v-model="selected"
      :options="options"
      :name="props.name"
      :label="props.label"
      :info="props.info"
      :disabled="!connected && !props.modelValue"
      searchable
      unsorted
    />
    <p v-if="missing" class="text-warning small" data-test="channel-missing">
      <i class="fa-light fa-triangle-exclamation" />
      {{ t("labels.fleet.discord.channelMissing") }}
    </p>
    <p
      v-else-if="!isLoading && channels && !connected"
      class="text-muted small"
      data-test="channel-unavailable"
    >
      {{ t(`labels.fleet.discord.statusCodes.${channels.code}`) }}
    </p>
  </div>
</template>
