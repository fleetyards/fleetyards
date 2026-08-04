<script lang="ts">
export default {
  name: "FleetSettingsRolesPage",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useFleetRoles as useFleetRolesQuery,
  useFleetResourceAccessCatalog,
  type Fleet,
  type FleetMember,
  type FleetResourceAccessGroup,
  type FleetRoleExtended,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

const fleetSlug = computed(() => route.params.slug as string);

const { data: roles } = useFleetRolesQuery(fleetSlug);
const { data: catalog } = useFleetResourceAccessCatalog();

// The top-level "fleet" group's manage privilege (fleet:manage) implies every
// other privilege across all groups; a group's own manage implies the rest of
// that group. Both are sourced from the catalog so no privilege list is hardcoded.
const globalManagePrivilege = computed(
  () => catalog.value?.find((group) => group.key === "fleet")?.managePrivilege,
);

const hasPrivilege = (role: FleetRoleExtended, privilege: string) => {
  return (
    (role.resourceAccess as string[] | undefined)?.includes(privilege) ?? false
  );
};

const isImpliedByManage = (
  role: FleetRoleExtended,
  group: FleetResourceAccessGroup,
  privilege: string,
) => {
  const globalManage = globalManagePrivilege.value;

  if (privilege === globalManage) return false;

  if (globalManage && hasPrivilege(role, globalManage)) {
    return !hasPrivilege(role, privilege);
  }

  if (
    group.managePrivilege &&
    privilege !== group.managePrivilege &&
    hasPrivilege(role, group.managePrivilege)
  ) {
    return !hasPrivilege(role, privilege);
  }

  return false;
};
</script>

<template>
  <div v-if="roles && catalog" class="fleet-roles">
    <Panel v-for="role in roles" :key="role.id" class="fleet-role">
      <PanelHeading :level="HeadingLevelEnum.H3">
        {{ role.name }}
        <span v-if="role.permanent" class="fleet-role-badge text-muted">
          ({{ t("labels.fleet.roles.permanent") }})
        </span>
      </PanelHeading>
      <PanelBody>
        <div class="fleet-role-privileges">
          <div
            v-for="group in catalog"
            :key="group.key"
            class="privilege-group"
          >
            <h4 class="privilege-group-name">
              {{ t(`labels.fleet.roles.privilegeGroups.${group.key}`) }}
            </h4>
            <ul class="privilege-list">
              <li
                v-for="privilege in group.privileges"
                :key="privilege"
                class="privilege-item"
                :class="{
                  active: hasPrivilege(role, privilege),
                  implied: isImpliedByManage(role, group, privilege),
                }"
              >
                <i
                  :class="
                    hasPrivilege(role, privilege)
                      ? 'fa-solid fa-check text-success'
                      : isImpliedByManage(role, group, privilege)
                        ? 'fa-solid fa-check text-info'
                        : 'fa-solid fa-times text-muted'
                  "
                />
                {{ t(`labels.fleet.roles.privileges.${privilege}`) }}
              </li>
            </ul>
          </div>
        </div>
      </PanelBody>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
.fleet-roles {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.fleet-role-badge {
  font-size: 0.75em;
  font-weight: normal;
}

.fleet-role-privileges {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 20px;
}

.privilege-group-name {
  margin: 0 0 8px;
  font-size: 0.9em;
  text-transform: uppercase;
  opacity: 0.7;
}

.privilege-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.privilege-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 0;
  opacity: 0.5;

  &.active {
    opacity: 1;
  }

  &.implied {
    opacity: 0.75;
    font-style: italic;
  }

  i {
    width: 16px;
    text-align: center;
  }
}
</style>
