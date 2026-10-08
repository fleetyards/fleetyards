<script lang="ts">
export default {
  name: "FleetSettingsSquadronsPage",
};
</script>

<script lang="ts" setup>
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Loader from "@/shared/components/Loader/index.vue";
import SquadronRanks from "@/frontend/components/Fleets/Squadrons/SquadronRanks/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type Fleet,
  type FleetMember,
  useFleetSquadronRoles,
  useUpdateFleet,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

const fleetSlug = computed(() => props.fleet.slug);

const canEnable = computed(
  () => props.membership?.capabilities?.enableSquadrons ?? false,
);

const canReadRanks = computed(
  () => props.membership?.capabilities?.readSquadrons ?? false,
);

const canRename = computed(
  () => props.membership?.capabilities?.manageSquadrons ?? false,
);

const squadronsEnabled = computed(() => props.fleet.squadronsEnabled);

const switching = ref(false);

// FormToggle keeps its own checked state, so a failed save remounts it from
// the setting the fleet still has.
const toggleKey = ref(0);
const updateMutation = useUpdateFleet();

// Saved on the switch itself: it is one setting, and a save button for it
// would be a second click that means nothing.
const onToggle = async (value: boolean) => {
  switching.value = true;

  await updateMutation
    .mutateAsync({
      slug: props.fleet.slug,
      data: { squadronsEnabled: value },
    })
    .then(() => {
      displaySuccess({ text: t("messages.fleet.update.success") });
      comlink.emit("fleet-update");
    })
    .catch(() => {
      toggleKey.value += 1;
      displayAlert({ text: t("messages.fleet.update.failure") });
    })
    .finally(() => {
      switching.value = false;
    });
};

// The ranks endpoint answers only while squadrons are switched on, and only
// to a role that reads squadrons -- `fleet:update` alone reaches this page
// for the switch.
const ranksVisible = computed(
  () => squadronsEnabled.value && canReadRanks.value,
);

const { data: ranks, isLoading } = useFleetSquadronRoles(fleetSlug, {
  query: { enabled: ranksVisible },
});
</script>

<template>
  <div class="row">
    <div class="col-12 col-md-6" data-tour="fleet-squadrons-switch">
      <FormToggle
        :key="toggleKey"
        :model-value="squadronsEnabled"
        name="squadronsEnabled"
        translation-key="fleet.squadronsEnabled"
        :disabled="!canEnable || switching"
        data-test="settings-squadrons-enabled"
        @update:model-value="onToggle"
      />
    </div>
  </div>

  <template v-if="ranksVisible">
    <Heading :level="HeadingLevelEnum.H2" mt>
      {{ t("headlines.fleets.squadrons.ranks") }}
    </Heading>

    <Loader :loading="isLoading" />

    <SquadronRanks
      v-if="ranks?.length"
      :fleet-slug="fleet.slug"
      :ranks="ranks"
      :editable="canRename"
    />
  </template>
</template>
