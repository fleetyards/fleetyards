<script lang="ts">
export default {
  name: "FleetDiscordRoleSelect",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetDiscordConnectionCodeEnum,
  useFleetDiscordRoles,
  type FilterOption,
} from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  modelValue?: string | null;
  name: string;
  label: string;
  info?: string;
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: null,
  info: undefined,
  disabled: false,
});

const emit = defineEmits<{ "update:modelValue": [value: string | null] }>();

const { t } = useI18n();

const { data: roles, isLoading } = useFleetDiscordRoles(
  computed(() => props.fleetSlug),
);

const connected = computed(
  () => roles.value?.code === FleetDiscordConnectionCodeEnum.OK,
);

const listed = computed(
  () =>
    !!props.modelValue &&
    !!roles.value?.items.some((role) => role.id === props.modelValue),
);

// Only a guild that answered can say a role is gone.
const missing = computed(
  () => connected.value && !!props.modelValue && !listed.value,
);

// Highest first, the order the API returns and Discord's own role list shows.
const options = computed<FilterOption[]>(() => {
  const items = (roles.value?.items ?? []).map((role) => ({
    value: role.id,
    label: `@${role.name}`,
  }));

  // The saved role stays selectable, and so clearable, whatever Discord says
  // about it.
  if (props.modelValue && !listed.value) {
    items.unshift({
      value: props.modelValue,
      label: missing.value
        ? t("labels.fleet.discord.missingRole")
        : props.modelValue,
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
  <div class="discord-role-select">
    <BaseSelect
      v-model="selected"
      :options="options"
      :name="props.name"
      :label="props.label"
      :info="props.info"
      :disabled="props.disabled || (!connected && !props.modelValue)"
      searchable
      unsorted
    />
    <p v-if="missing" class="text-warning small" data-test="role-missing">
      <i class="fa-light fa-triangle-exclamation" />
      {{ t("labels.fleet.discord.roleMissing") }}
    </p>
    <p
      v-else-if="!isLoading && roles && !connected"
      class="text-muted small"
      data-test="role-unavailable"
    >
      {{ t(`labels.fleet.discord.statusCodes.${roles.code}`) }}
    </p>
  </div>
</template>
