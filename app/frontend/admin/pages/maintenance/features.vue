<script lang="ts">
export default {
  name: "AdminFeaturesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Toggle from "@/shared/components/base/Toggle/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import UserFilterGroup from "@/admin/components/base/UserFilterGroup/index.vue";
import FleetFilterGroup from "@/admin/components/base/FleetFilterGroup/index.vue";
import {
  useAdminFeatures,
  getAdminFeaturesQueryKey,
  enableAdminFeature,
  disableAdminFeature,
  enableAdminFeatureActor,
  disableAdminFeatureActor,
  enableAdminFeatureGroup,
  disableAdminFeatureGroup,
  toggleAdminFeatureSelfService,
  type Feature,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const { data: features, isLoading } = useAdminFeatures();
const queryClient = useQueryClient();
const invalidateFeatures = () =>
  queryClient.invalidateQueries({ queryKey: getAdminFeaturesQueryKey() });

interface FeatureItem extends Feature {
  id: string;
}

const featureItems = computed<FeatureItem[]>(() => {
  if (!features.value) return [];
  return features.value.map((f) => ({ ...f, id: f.name }));
});

const editableList = ref<{
  editingId: string | null;
  creating: boolean;
  finishEdit: () => void;
} | null>(null);

// Edit form state
const editActorType = ref("User");
const selectedUser = ref<string | undefined>(undefined);
const selectedFleet = ref<string | undefined>(undefined);

const actorTypeOptions = [
  { label: t("labels.features.user"), value: "User" },
  { label: t("labels.features.fleet"), value: "Fleet" },
];

const availableGroups = ["testers", "admins"];

const toggleFeature = async (feature: FeatureItem) => {
  try {
    if (feature.state === "on") {
      await disableAdminFeature(feature.name);
    } else {
      await enableAdminFeature(feature.name);
    }
    void invalidateFeatures();
    displaySuccess({ text: t("messages.features.updated") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  }
};

const addActor = async (feature: FeatureItem) => {
  const actorId =
    editActorType.value === "User" ? selectedUser.value : selectedFleet.value;
  if (!actorId) return;

  try {
    await enableAdminFeatureActor(feature.name, {
      actor_type: editActorType.value,
      actor_id: actorId,
    });
    void invalidateFeatures();
    selectedUser.value = undefined;
    selectedFleet.value = undefined;
    displaySuccess({ text: t("messages.features.actorAdded") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  }
};

const removeActor = async (featureName: string, type: string, id: string) => {
  try {
    await disableAdminFeatureActor(featureName, {
      actor_type: type,
      actor_id: id,
    });
    void invalidateFeatures();
    displaySuccess({ text: t("messages.features.actorRemoved") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  }
};

const addGroup = async (featureName: string, group: string) => {
  try {
    await enableAdminFeatureGroup(featureName, { group });
    void invalidateFeatures();
    displaySuccess({ text: t("messages.features.groupAdded") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  }
};

const removeGroup = async (featureName: string, group: string) => {
  try {
    await disableAdminFeatureGroup(featureName, { group });
    void invalidateFeatures();
    displaySuccess({ text: t("messages.features.groupRemoved") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  }
};

const toggleSelfServiceFlag = async (feature: FeatureItem) => {
  try {
    await toggleAdminFeatureSelfService(feature.name);
    void invalidateFeatures();
    displaySuccess({ text: t("messages.features.updated") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  }
};

const onStartEdit = (_item: FeatureItem) => {
  editActorType.value = "User";
  selectedUser.value = undefined;
  selectedFleet.value = undefined;
};

const onSaveEdit = () => {
  editableList.value?.finishEdit();
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

const hasSelectedActor = computed(() => {
  return editActorType.value === "User"
    ? !!selectedUser.value
    : !!selectedFleet.value;
});
</script>

<template>
  <Heading hero>{{ t("headlines.admin.features.index") }}</Heading>

  <InlineEditableList
    ref="editableList"
    empty-name="features"
    :loading="isLoading"
    :items="featureItems"
    hide-destroy
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
  >
    <template #display="{ item }">
      <BasePill :variant="stateVariant(item.state)" uppercase margin-right>
        {{ stateLabel(item.state) }}
      </BasePill>
      <span class="feature-name">{{ item.name }}</span>
      <BasePill v-if="item.selfService" margin-right>
        {{ t("labels.features.selfService") }}
      </BasePill>
      <BasePill v-if="item.groups.length > 0" margin-right>
        {{ item.groups.join(", ") }}
      </BasePill>
      <BasePill v-if="item.actors.length > 0" margin-right>
        {{ item.actors.length }} {{ t("labels.features.actors") }}
      </BasePill>
    </template>

    <template #actions="{ item }">
      <Toggle
        :active="item.state === 'on'"
        @toggle="toggleFeature(item)"
      />
    </template>

    <template #edit="{ item }">
      <div class="edit-feature">
        <div class="edit-section">
          <h4>{{ t("headlines.admin.features.selfService") }}</h4>
          <Toggle
            :active="item.selfService"
            :label="
              item.selfService
                ? t('labels.features.selfServiceEnabled')
                : t('labels.features.selfServiceDisabled')
            "
            @toggle="toggleSelfServiceFlag(item)"
          />
        </div>

        <div class="edit-section">
          <h4>{{ t("headlines.admin.features.groups") }}</h4>
          <div class="edit-groups">
            <div
              v-for="group in item.groups"
              :key="group"
              class="edit-group-item"
            >
              <BasePill margin-right>{{ group }}</BasePill>
              <Btn
                :size="BtnSizesEnum.SMALL"
                inline
                @click.prevent="removeGroup(item.name, group)"
              >
                <i class="fa-duotone fa-times" />
              </Btn>
            </div>
            <Btn
              v-for="group in availableGroups.filter(
                (g) => !item.groups.includes(g),
              )"
              :key="group"
              :size="BtnSizesEnum.SMALL"
              inline
              @click.prevent="addGroup(item.name, group)"
            >
              <i class="fa-duotone fa-plus" />
              {{ group }}
            </Btn>
          </div>
        </div>

        <div class="edit-section">
          <h4>{{ t("headlines.admin.features.actors") }}</h4>
          <div v-if="item.actors.length > 0" class="edit-actors">
            <div
              v-for="actor in item.actors"
              :key="`${actor.type};${actor.id}`"
              class="edit-actor-item"
            >
              <BasePill uppercase margin-right>{{ actor.type }}</BasePill>
              <span>{{ actor.name }}</span>
              <Btn
                :size="BtnSizesEnum.SMALL"
                inline
                @click.prevent="removeActor(item.name, actor.type, actor.id)"
              >
                <i class="fa-duotone fa-times" />
              </Btn>
            </div>
          </div>

          <div class="add-actor-form">
            <FilterGroup
              v-model="editActorType"
              name="actor-type"
              :options="actorTypeOptions"
              :nullable="false"
              :label="t('labels.features.actorType')"
            />
            <UserFilterGroup
              v-if="editActorType === 'User'"
              v-model="selectedUser"
              name="feature-user"
              :no-label="false"
            />
            <FleetFilterGroup
              v-if="editActorType === 'Fleet'"
              v-model="selectedFleet"
              name="feature-fleet"
              :no-label="false"
            />
            <Btn
              :size="BtnSizesEnum.SMALL"
              :disabled="!hasSelectedActor"
              @click.prevent="addActor(item)"
            >
              <i class="fa-duotone fa-plus" />
              {{ t("actions.addActor") }}
            </Btn>
          </div>
        </div>
      </div>
    </template>
  </InlineEditableList>
</template>

<style lang="scss" scoped>
.feature-name {
  font-weight: 600;
  margin-right: 0.5rem;
}

.edit-feature {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  width: 100%;
}

.edit-section {
  h4 {
    margin: 0 0 0.5rem;
    font-size: 0.9rem;
  }
}

.edit-groups {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
}

.edit-group-item {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
}

.edit-actors {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin-bottom: 0.75rem;
}

.edit-actor-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.add-actor-form {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  gap: 0.75rem;
  margin-top: 0.5rem;
}
</style>
