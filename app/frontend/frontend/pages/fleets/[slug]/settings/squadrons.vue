<script lang="ts">
export default {
  name: "FleetSettingsSquadronsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Grid from "@/shared/components/base/Grid/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import SquadronPanel from "@/frontend/components/Fleets/Squadrons/SquadronPanel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import {
  type Fleet,
  type FleetMember,
  type FleetSquadron,
  useFleetSquadrons,
  useDestroyFleetSquadron,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const fleetSlug = computed(() => props.fleet.slug);

const canCreate = computed(
  () => props.membership?.capabilities?.createSquadrons ?? false,
);

const canUpdate = computed(
  () => props.membership?.capabilities?.updateSquadrons ?? false,
);

const canDestroy = computed(
  () => props.membership?.capabilities?.destroySquadrons ?? false,
);

const canManageMembers = computed(
  () => props.membership?.capabilities?.manageSquadronMembers ?? false,
);

const {
  data: squadrons,
  isLoading,
  refetch,
} = useFleetSquadrons(fleetSlug, {});

const squadronList = computed<FleetSquadron[]>(
  () => squadrons.value?.items ?? [],
);

const openSquadronModal = (squadron?: FleetSquadron) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SquadronModal/index.vue"),
    props: { fleet: props.fleet, squadron },
  });
};

const openMemberPicker = (squadron: FleetSquadron) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SquadronMemberPicker/index.vue"),
    props: { fleet: props.fleet, squadron },
  });
};

const destroyMutation = useDestroyFleetSquadron();

const onDestroy = (squadron: FleetSquadron) => {
  displayConfirm({
    text: t("messages.fleet.squadrons.destroy.confirm", {
      name: squadron.name,
    }),
    confirmText: t("actions.delete"),
    tone: AppConfirmTonesEnum.DANGER,
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync({ fleetSlug: props.fleet.slug, slug: squadron.slug })
        .then(() => {
          displaySuccess({
            text: t("messages.fleet.squadrons.destroy.success"),
          });
          void refetch();
        })
        .catch(() => {
          displayAlert({
            text: t("messages.fleet.squadrons.destroy.failure"),
          });
        });
    },
  });
};

const squadronCreatedComlink = ref();
const squadronUpdatedComlink = ref();
const squadronMembersComlink = ref();

onMounted(() => {
  squadronCreatedComlink.value = comlink.on(
    "fleet-squadron-created",
    () => void refetch(),
  );
  squadronUpdatedComlink.value = comlink.on(
    "fleet-squadron-updated",
    () => void refetch(),
  );
  squadronMembersComlink.value = comlink.on(
    "fleet-squadron-members-updated",
    () => void refetch(),
  );
});

onUnmounted(() => {
  squadronCreatedComlink.value();
  squadronUpdatedComlink.value();
  squadronMembersComlink.value();
});
</script>

<template>
  <Teleport to="#header-right">
    <Btn
      v-if="canCreate"
      :size="BtnSizesEnum.MD"
      mobile-icon-only
      data-test="settings-create-squadron"
      @click="openSquadronModal()"
    >
      <i class="fa-light fa-plus" />
      {{ t("actions.fleet.squadrons.create") }}
    </Btn>
  </Teleport>

  <Loader :loading="isLoading" />

  <Grid v-if="squadronList.length" :records="squadronList" primary-key="id">
    <template #default="{ record }">
      <SquadronPanel
        :squadron="record"
        :to="{
          name: 'fleet-squadron',
          params: { slug: fleet.slug, squadron: record.slug },
        }"
        :editable="canUpdate"
        :destroyable="canDestroy"
        :members-manageable="canManageMembers"
        @edit="openSquadronModal(record)"
        @destroy="onDestroy(record)"
        @add-members="openMemberPicker(record)"
      />
    </template>
  </Grid>

  <Empty
    v-else-if="!isLoading"
    :name="t('labels.fleet.squadrons.index')"
    data-test="settings-squadrons-empty"
  />
</template>
