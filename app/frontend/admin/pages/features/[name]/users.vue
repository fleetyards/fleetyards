<script lang="ts">
export default {
  name: "AdminFeatureUsersPage",
};
</script>

<script lang="ts" setup>
import { type Feature, type FeatureActor } from "@/services/fyAdminApi";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import UserSelect from "@/admin/components/base/UserSelect/index.vue";
import ActorList from "@/admin/components/Features/ActorList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatureActions } from "@/admin/composables/useFeatureActions";

type Props = {
  feature: Feature;
};

const props = defineProps<Props>();

const { t } = useI18n();

const users = computed(() =>
  props.feature.actors.filter((actor) => actor.type === "User"),
);

const actions = useFeatureActions(() => props.feature.name);

const selectedUser = ref<string>();

const add = async () => {
  if (!selectedUser.value) return;

  if (await actions.addActor("User", selectedUser.value)) {
    selectedUser.value = undefined;
  }
};

const remove = (actor: FeatureActor) => actions.removeActor("User", actor.id);
</script>

<template>
  <div class="feature-actors-page">
    <Panel>
      <PanelHeading>
        {{ t("headlines.admin.features.addUser") }}
      </PanelHeading>
      <PanelBody>
        <section class="feature-section">
          <div class="feature-add-actor">
            <UserSelect
              v-model="selectedUser"
              name="feature-user"
              value-attr="id"
              inline
            />
            <Btn
              :disabled="!selectedUser"
              :loading="actions.busy.value"
              data-test="feature-add-user"
              @click="add"
            >
              <i class="fa-duotone fa-plus" />
              {{ t("actions.add") }}
            </Btn>
          </div>
        </section>
      </PanelBody>
    </Panel>

    <Panel>
      <PanelHeading>
        {{ t("headlines.admin.features.enabledUsers") }}
        <span class="text-muted">({{ users.length }})</span>
      </PanelHeading>
      <PanelBody>
        <section class="feature-section">
          <ActorList
            :actors="users"
            name="users"
            :filter-label="t('labels.features.filterUsers')"
            :empty-text="t('labels.features.noUsers')"
            @remove="remove"
          />
        </section>
      </PanelBody>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
@import "./actors";
</style>
