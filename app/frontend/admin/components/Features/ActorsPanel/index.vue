<script lang="ts">
export default {
  name: "FeatureActorsPanel",
};
</script>

<script lang="ts" setup>
import { type Feature, type FeatureActor } from "@/services/fyAdminApi";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import UserSelect from "@/admin/components/base/UserSelect/index.vue";
import FleetSelect from "@/admin/components/base/FleetSelect/index.vue";
import ActorList from "@/admin/components/Features/ActorList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useFeatureActions,
  type FeatureActorType,
} from "@/admin/composables/useFeatureActions";

interface Props {
  feature: Feature;
}

const props = defineProps<Props>();

const { t } = useI18n();

const actions = useFeatureActions(() => props.feature.name);

const kind = ref<FeatureActorType>("User");

const actorsOf = (type: FeatureActorType) =>
  props.feature.actors.filter((actor) => actor.type === type);

const users = computed(() => actorsOf("User"));
const fleets = computed(() => actorsOf("Fleet"));

const selectedUser = ref<string>();
const selectedFleet = ref<string>();

const enabledFids = computed(() =>
  fleets.value.flatMap((fleet) => (fleet.fid ? [fleet.fid] : [])),
);

const fleetAlreadyEnabled = computed(
  () =>
    !!selectedFleet.value && enabledFids.value.includes(selectedFleet.value),
);

const selected = computed(() =>
  kind.value === "User" ? selectedUser.value : selectedFleet.value,
);

const canAdd = computed(
  () =>
    !!selected.value && !(kind.value === "Fleet" && fleetAlreadyEnabled.value),
);

const add = async () => {
  if (!selected.value || !canAdd.value) return;

  if (await actions.addActor(kind.value, selected.value)) {
    if (kind.value === "User") {
      selectedUser.value = undefined;
    } else {
      selectedFleet.value = undefined;
    }
  }
};

const remove = (actor: FeatureActor) =>
  actions.removeActor(kind.value, actor.id);
</script>

<template>
  <Panel :outer-spacing="false">
    <PanelHeading>{{
      t("headlines.admin.features.usersAndFleets")
    }}</PanelHeading>
    <PanelBody>
      <div class="feature-actors">
        <div class="feature-actors__toolbar">
          <BtnGroup
            segmented
            :aria-label="t('headlines.admin.features.usersAndFleets')"
          >
            <Btn
              :active="kind === 'User'"
              data-test="feature-actors-tab-users"
              @click="kind = 'User'"
            >
              {{ t("labels.features.usersTab", { count: users.length }) }}
            </Btn>
            <Btn
              :active="kind === 'Fleet'"
              data-test="feature-actors-tab-fleets"
              @click="kind = 'Fleet'"
            >
              {{ t("labels.features.fleetsTab", { count: fleets.length }) }}
            </Btn>
          </BtnGroup>

          <div class="feature-actors__add">
            <UserSelect
              v-if="kind === 'User'"
              v-model="selectedUser"
              class="feature-actors__select"
              name="feature-user"
              value-attr="id"
              inline
            />
            <FleetSelect
              v-else
              v-model="selectedFleet"
              class="feature-actors__select"
              name="feature-fleet"
              inline
            />
            <Btn
              :disabled="!canAdd"
              :loading="actions.busy.value"
              :data-test="
                kind === 'User' ? 'feature-add-user' : 'feature-add-fleet'
              "
              @click="add"
            >
              <i class="fa-light fa-plus" aria-hidden="true" />
              {{ t("actions.add") }}
            </Btn>
          </div>
        </div>

        <p
          v-if="kind === 'Fleet' && fleetAlreadyEnabled"
          class="feature-actors__note"
          data-test="feature-fleet-already-enabled"
        >
          <i class="fa-light fa-check" aria-hidden="true" />
          {{ t("labels.features.alreadyEnabled") }}
        </p>

        <ActorList
          v-if="kind === 'User'"
          key="users"
          :actors="users"
          name="users"
          :filter-label="t('labels.features.filterUsers')"
          :empty-text="t('labels.features.noUsers')"
          @remove="remove"
        />
        <ActorList
          v-else
          key="fleets"
          :actors="fleets"
          name="fleets"
          :filter-label="t('labels.features.filterFleets')"
          :empty-text="t('labels.features.noFleets')"
          @remove="remove"
        />
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.feature-actors {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.feature-actors__toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem 1rem;
}

.feature-actors__add {
  display: flex;
  flex: 0 1 32rem;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
  min-width: 0;
}

.feature-actors__select {
  flex: 1 1 16rem;
  min-width: 0;
}

.feature-actors__note {
  margin: 0;
  color: var(--color-text-dim);
}
</style>
