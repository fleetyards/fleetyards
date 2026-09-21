<script lang="ts">
export default {
  name: "FleetSettingsSquadronsPage",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import SquadronBadge from "@/frontend/components/Fleets/Squadrons/SquadronBadge/index.vue";
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

  <Panel v-if="squadronList.length">
    <PanelBody>
      <ul class="squadron-settings-list">
        <li
          v-for="squadron in squadronList"
          :key="squadron.id"
          class="squadron-settings-row"
          :data-test="`settings-squadron-${squadron.slug}`"
        >
          <SquadronBadge
            :squadron="squadron"
            :to="{
              name: 'fleet-squadron',
              params: { slug: fleet.slug, squadron: squadron.slug },
            }"
          />
          <span class="squadron-settings-count text-muted">
            {{
              t("labels.fleet.squadrons.memberCount", {
                count: squadron.memberCount,
              })
            }}
          </span>
          <div class="squadron-settings-actions">
            <Btn
              v-if="canManageMembers"
              :size="BtnSizesEnum.SM"
              @click="openMemberPicker(squadron)"
            >
              <i class="fa-duotone fa-user-plus" />
            </Btn>
            <Btn
              v-if="canUpdate"
              :size="BtnSizesEnum.SM"
              @click="openSquadronModal(squadron)"
            >
              <i class="fa-duotone fa-pen" />
            </Btn>
            <Btn
              v-if="canDestroy"
              :size="BtnSizesEnum.SM"
              @click="onDestroy(squadron)"
            >
              <i class="fa-duotone fa-trash" />
            </Btn>
          </div>
        </li>
      </ul>
    </PanelBody>
  </Panel>

  <Empty
    v-else-if="!isLoading"
    :name="t('labels.fleet.squadrons.index')"
    data-test="settings-squadrons-empty"
  />
</template>

<style lang="scss" scoped>
.squadron-settings-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.squadron-settings-row {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.squadron-settings-count {
  flex: 1;
  min-width: 0;
}

.squadron-settings-actions {
  display: flex;
  gap: 6px;
}
</style>
