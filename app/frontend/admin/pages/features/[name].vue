<script lang="ts">
export default {
  name: "AdminFeatureDetailPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import UserFilterGroup from "@/admin/components/base/UserFilterGroup/index.vue";
import FleetFilterGroup from "@/admin/components/base/FleetFilterGroup/index.vue";
import {
  BtnVariantsEnum,
  BtnSizesEnum,
} from "@/shared/components/base/Btn/types";
import {
  useAdminFeature,
  getAdminFeaturesQueryKey,
  enableAdminFeature,
  disableAdminFeature,
  enableAdminFeatureActor,
  disableAdminFeatureActor,
  enableAdminFeatureGroup,
  disableAdminFeatureGroup,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const route = useRoute();

const featureName = computed(() => route.params.name as string);

const { data: feature, isLoading } = useAdminFeature(featureName);
const queryClient = useQueryClient();
const invalidateFeatures = () =>
  queryClient.invalidateQueries({ queryKey: getAdminFeaturesQueryKey() });

const toggling = ref(false);

const toggleGlobal = async () => {
  if (!feature.value) return;
  toggling.value = true;
  try {
    if (feature.value.state === "on") {
      await disableAdminFeature(feature.value.name);
    } else {
      await enableAdminFeature(feature.value.name);
    }
    void invalidateFeatures();
    displaySuccess({ text: t("messages.features.updated") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  } finally {
    toggling.value = false;
  }
};

// Actor management
const actorType = ref("User");
const selectedUser = ref<string | undefined>(undefined);
const selectedFleet = ref<string | undefined>(undefined);
const addingActor = ref(false);

const actorTypeOptions = [
  { label: t("labels.features.user"), value: "User" },
  { label: t("labels.features.fleet"), value: "Fleet" },
];

const hasSelectedActor = computed(() => {
  return actorType.value === "User"
    ? !!selectedUser.value
    : !!selectedFleet.value;
});

const addActor = async () => {
  if (!feature.value) return;
  const actorId =
    actorType.value === "User" ? selectedUser.value : selectedFleet.value;
  if (!actorId) return;

  addingActor.value = true;
  try {
    await enableAdminFeatureActor(feature.value.name, {
      actor_type: actorType.value,
      actor_id: actorId,
    });
    void invalidateFeatures();
    selectedUser.value = undefined;
    selectedFleet.value = undefined;
    displaySuccess({ text: t("messages.features.actorAdded") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  } finally {
    addingActor.value = false;
  }
};

const removeActor = async (type: string, id: string) => {
  if (!feature.value) return;
  try {
    await disableAdminFeatureActor(feature.value.name, {
      actor_type: type,
      actor_id: id,
    });
    void invalidateFeatures();
    displaySuccess({ text: t("messages.features.actorRemoved") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  }
};

// Group management
const availableGroups = ["testers", "admins"];
const addingGroup = ref(false);

const addGroup = async (group: string) => {
  if (!feature.value) return;
  addingGroup.value = true;
  try {
    await enableAdminFeatureGroup(feature.value.name, { group });
    void invalidateFeatures();
    displaySuccess({ text: t("messages.features.groupAdded") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  } finally {
    addingGroup.value = false;
  }
};

const removeGroup = async (group: string) => {
  if (!feature.value) return;
  try {
    await disableAdminFeatureGroup(feature.value.name, { group });
    void invalidateFeatures();
    displaySuccess({ text: t("messages.features.groupRemoved") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  }
};

const stateVariant = (
  state: string,
): "success" | "danger" | "warning" | "default" => {
  switch (state) {
    case "on":
      return "success";
    case "off":
      return "danger";
    case "conditional":
      return "warning";
    default:
      return "default";
  }
};

const stateLabel = (state: string) => {
  switch (state) {
    case "on":
      return t("labels.features.stateOn");
    case "off":
      return t("labels.features.stateOff");
    case "conditional":
      return t("labels.features.stateConditional");
    default:
      return state;
  }
};
</script>

<template>
  <div v-if="isLoading" class="text-center">
    <i class="fa-duotone fa-spinner fa-spin fa-2x" />
  </div>

  <template v-else-if="feature">
    <Heading hero>
      {{ feature.name }}
      <template #small>
        <BasePill v-if="feature.selfService">
          {{ t("labels.features.selfService") }}
        </BasePill>
      </template>
    </Heading>

    <!-- Global State -->
    <Panel>
      <h3>{{ t("headlines.admin.features.globalState") }}</h3>
      <div class="global-state">
        <span class="state-label">
          {{ t("labels.features.currentState") }}:
          <BasePill :variant="stateVariant(feature.state)" uppercase>
            {{ stateLabel(feature.state) }}
          </BasePill>
        </span>
        <Btn
          :variant="
            feature.state === 'on'
              ? BtnVariantsEnum.DANGER
              : BtnVariantsEnum.DEFAULT
          "
          :loading="toggling"
          @click.prevent="toggleGlobal"
        >
          {{
            feature.state === "on"
              ? t("actions.disableGlobally")
              : t("actions.enableGlobally")
          }}
        </Btn>
      </div>
    </Panel>

    <!-- Groups -->
    <Panel>
      <h3>{{ t("headlines.admin.features.groups") }}</h3>
      <div v-if="feature.groups.length > 0" class="groups-list">
        <div v-for="group in feature.groups" :key="group" class="group-item">
          <BasePill margin-right>{{ group }}</BasePill>
          <Btn
            :size="BtnSizesEnum.SMALL"
            :variant="BtnVariantsEnum.DANGER"
            @click.prevent="removeGroup(group)"
          >
            {{ t("actions.remove") }}
          </Btn>
        </div>
      </div>
      <p v-else class="text-muted">
        {{ t("labels.features.noGroups") }}
      </p>
      <div class="add-group">
        <Btn
          v-for="group in availableGroups.filter(
            (g) => !feature!.groups.includes(g),
          )"
          :key="group"
          :size="BtnSizesEnum.SMALL"
          :loading="addingGroup"
          @click.prevent="addGroup(group)"
        >
          {{ t("actions.addGroup", { group }) }}
        </Btn>
      </div>
    </Panel>

    <!-- Actors -->
    <Panel>
      <h3>{{ t("headlines.admin.features.actors") }}</h3>
      <div v-if="feature.actors.length > 0" class="actors-list">
        <div
          v-for="actor in feature.actors"
          :key="`${actor.type};${actor.id}`"
          class="actor-item"
        >
          <BasePill uppercase margin-right>{{ actor.type }}</BasePill>
          <span class="actor-name">{{ actor.name }}</span>
          <Btn
            :size="BtnSizesEnum.SMALL"
            :variant="BtnVariantsEnum.DANGER"
            @click.prevent="removeActor(actor.type, actor.id)"
          >
            {{ t("actions.remove") }}
          </Btn>
        </div>
      </div>
      <p v-else class="text-muted">
        {{ t("labels.features.noActors") }}
      </p>

      <h4>{{ t("headlines.admin.features.addActor") }}</h4>
      <div class="add-actor-form">
        <FilterGroup
          v-model="actorType"
          name="actor-type"
          :options="actorTypeOptions"
          :nullable="false"
          :label="t('labels.features.actorType')"
        />
        <UserFilterGroup
          v-if="actorType === 'User'"
          v-model="selectedUser"
          name="feature-user"
          :no-label="false"
        />
        <FleetFilterGroup
          v-if="actorType === 'Fleet'"
          v-model="selectedFleet"
          name="feature-fleet"
          :no-label="false"
        />
        <Btn
          :size="BtnSizesEnum.SMALL"
          :loading="addingActor"
          :disabled="!hasSelectedActor"
          @click.prevent="addActor"
        >
          {{ t("actions.addActor") }}
        </Btn>
      </div>
    </Panel>
  </template>
</template>

<style lang="scss" scoped>
.global-state {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.state-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1rem;
}

.groups-list,
.actors-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.group-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.5rem 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.actor-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.actor-name {
  flex: 1;
  min-width: 0;
}

.add-group {
  display: flex;
  gap: 0.5rem;
  margin-top: 0.5rem;
}

.add-actor-form {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  gap: 1rem;
}

.text-muted {
  color: var(--text-muted);
  font-style: italic;
}
</style>
