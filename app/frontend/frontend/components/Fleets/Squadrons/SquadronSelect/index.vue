<script lang="ts">
export default {
  name: "FleetSquadronSelect",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  useFleetSquadrons,
  type Fleet,
  type FilterOption,
  type FleetSquadronRef,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  modelValue?: string[];
  // The squadrons the record being edited is already held to.
  assigned?: FleetSquadronRef[];
  name?: string;
  // Only events are announced on Discord, so only their form asks.
  warnWithoutDiscordChannel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: () => [],
  assigned: () => [],
  name: "fleetSquadronIds",
  warnWithoutDiscordChannel: false,
});

const emit = defineEmits<{ "update:modelValue": [value: string[]] }>();

const { t } = useI18n();

const { isFleetSquadronsEnabled } = useFeatures();

// Same gate the filter uses: no feature, no request.
const enabled = computed(() => isFleetSquadronsEnabled(props.fleet));

const { data: squadrons } = useFleetSquadrons(
  computed(() => props.fleet.slug),
  { perPage: "all" },
  { query: { enabled } },
);

/*
 * Squadrons before teams, the fleet's own order within each -- the same order
 * every other list of them uses, so the one somebody is looking for is where
 * they last saw it.
 *
 * With squadrons switched off the list is neither fetched nor trusted from
 * cache, but a record still held to squadrons keeps that restriction, so its
 * own squadrons stay listed to be kept or dropped.
 */
const options = computed<FilterOption[]>(() =>
  (enabled.value ? (squadrons.value?.items ?? []) : props.assigned).map(
    (squadron) => ({
      value: squadron.id,
      label: squadron.name,
    }),
  ),
);

/*
 * A squadron event is announced only in its squadrons' own channels, so a
 * squadron without one hears nothing -- said here, where it is picked, rather
 * than discovered from a silent channel.
 */
const withoutDiscordChannel = computed(() =>
  props.warnWithoutDiscordChannel && enabled.value
    ? (squadrons.value?.items ?? [])
        .filter(
          (squadron) =>
            props.modelValue.includes(squadron.id) &&
            !squadron.discordChannelId,
        )
        .map((squadron) => squadron.name)
    : [],
);

const selected = computed({
  get: () => props.modelValue,
  set: (value: string[]) => emit("update:modelValue", value ?? []),
});
</script>

<template>
  <div>
    <BaseSelect
      v-model="selected"
      :options="options"
      :name="props.name"
      :label="t('labels.fleet.squadrons.index')"
      :info="t('labels.fleet.squadrons.restrictedToHint')"
      multiple
      :nullable="false"
      searchable
    />
    <p
      v-if="withoutDiscordChannel.length"
      class="text-warning small"
      data-test="squadrons-not-announced"
    >
      <i class="fa-brands fa-discord" />
      {{
        t("labels.fleet.squadrons.notAnnounced", {
          names: withoutDiscordChannel.join(", "),
        })
      }}
    </p>
  </div>
</template>
