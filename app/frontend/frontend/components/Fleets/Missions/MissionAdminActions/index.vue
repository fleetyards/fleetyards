<script lang="ts">
export default {
  name: "FleetMissionAdminActions",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type Fleet,
  type MissionExtended,
  useDestroyFleetMission,
  useUpdateFleetMission,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { checkAccess } from "@/shared/utils/Access";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  mission: MissionExtended;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const comlink = useComlink();
const router = useRouter();

const canEdit = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:missions:manage",
    "fleet:missions:update",
  ]),
);

const canDelete = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:missions:manage",
    "fleet:missions:delete",
  ]),
);

const canCreateEvents = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:events:manage",
    "fleet:events:create",
  ]),
);

const archived = computed(() => !!props.mission.archived);

const destroyMutation = useDestroyFleetMission();
const updateMutation = useUpdateFleetMission();

const goToEdit = () => {
  void router.push({
    name: "fleet-mission-edit",
    params: { slug: props.fleet.slug, mission: props.mission.slug },
  });
};

const goToSpawnEvent = () => {
  void router.push({
    name: "fleet-event-new",
    params: { slug: props.fleet.slug },
    query: { mission: props.mission.slug },
  });
};

const performArchive = async () => {
  try {
    await destroyMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: props.mission.slug,
    });
    displaySuccess({ text: t("messages.fleets.mission.archive.success") });
    comlink.emit("fleet-mission-updated");
  } catch {
    displayAlert({ text: t("messages.fleets.mission.archive.failure") });
  }
};

const unarchive = async () => {
  try {
    await updateMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: props.mission.slug,
      data: { archivedAt: null },
    });
    displaySuccess({ text: t("messages.fleets.mission.unarchive.success") });
    comlink.emit("fleet-mission-updated");
  } catch {
    displayAlert({ text: t("messages.fleets.mission.unarchive.failure") });
  }
};

const performDestroy = async () => {
  try {
    await destroyMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: props.mission.slug,
    });
    displaySuccess({ text: t("messages.fleets.mission.destroy.success") });
    void router.push({
      name: "fleet-missions",
      params: { slug: props.fleet.slug },
    });
  } catch {
    displayAlert({ text: t("messages.fleets.mission.destroy.failure") });
  }
};

const handleDestroy = () => {
  displayConfirm({
    text: t("messages.fleets.mission.destroy.confirm"),
    confirmText: t("actions.fleets.missions.destroy"),
    onConfirm: performDestroy,
  });
};
</script>

<template>
  <BtnGroup inline>
    <Btn v-if="canEdit" :size="BtnSizesEnum.SMALL" inline @click="goToEdit">
      <i class="fa-light fa-pen" />
      <span>{{ t("actions.fleets.missions.edit") }}</span>
    </Btn>
    <BtnDropdown :size="BtnSizesEnum.SMALL" inline>
      <Btn
        v-if="canCreateEvents && !archived"
        :size="BtnSizesEnum.SMALL"
        inline
        @click="goToSpawnEvent"
      >
        <i class="fa-light fa-calendar-plus" />
        <span>{{ t("actions.fleets.events.spawn") }}</span>
      </Btn>
      <Btn
        v-if="archived"
        :size="BtnSizesEnum.SMALL"
        inline
        :loading="updateMutation.isPending.value"
        @click="unarchive"
      >
        <i class="fa-light fa-box-open" />
        <span>{{ t("actions.fleets.missions.unarchive") }}</span>
      </Btn>
      <Btn
        v-if="canDelete && !archived"
        :size="BtnSizesEnum.SMALL"
        inline
        variant="danger"
        :loading="destroyMutation.isPending.value"
        @click="performArchive"
      >
        <i class="fa-light fa-archive" />
        <span>{{ t("actions.fleets.missions.archive") }}</span>
      </Btn>
      <Btn
        v-if="canDelete && archived"
        :size="BtnSizesEnum.SMALL"
        inline
        variant="danger"
        @click="handleDestroy"
      >
        <i class="fa-light fa-trash" />
        <span>{{ t("actions.fleets.missions.destroy") }}</span>
      </Btn>
    </BtnDropdown>
  </BtnGroup>
</template>
