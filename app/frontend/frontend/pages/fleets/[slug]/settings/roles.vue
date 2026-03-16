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
  type Fleet,
  type FleetMember,
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

const privilegeGroups: Record<string, string[]> = {
  fleet: [
    "fleet:update",
    "fleet:update:images",
    "fleet:update:description",
    "fleet:delete",
    "fleet:manage",
  ],
  memberships: [
    "fleet:memberships:read",
    "fleet:memberships:create",
    "fleet:memberships:update",
    "fleet:memberships:delete",
    "fleet:memberships:manage",
  ],
  invites: [
    "fleet:invites:read",
    "fleet:invites:create",
    "fleet:invites:delete",
    "fleet:invites:manage",
  ],
  vehicles: [
    "fleet:vehicles:read",
    "fleet:vehicles:create",
    "fleet:vehicles:update",
    "fleet:vehicles:delete",
    "fleet:vehicles:manage",
  ],
  roles: [
    "fleet:roles:read",
    "fleet:roles:create",
    "fleet:roles:update",
    "fleet:roles:delete",
    "fleet:roles:manage",
  ],
};

const hasPrivilege = (role: FleetRoleExtended, privilege: string) => {
  return role.resourceAccess?.includes(privilege) ?? false;
};

const isImpliedByManage = (role: FleetRoleExtended, privilege: string) => {
  if (privilege === "fleet:manage") return false;

  // fleet:manage implies everything (including other :manage privileges)
  if (hasPrivilege(role, "fleet:manage")) {
    return !hasPrivilege(role, privilege);
  }

  // group-level :manage implies other privileges in the same group
  if (!privilege.endsWith(":manage")) {
    const prefix = privilege.substring(0, privilege.lastIndexOf(":"));
    const manageKey = `${prefix}:manage`;

    return !hasPrivilege(role, privilege) && hasPrivilege(role, manageKey);
  }

  return false;
};
</script>

<template>
  <div v-if="roles" class="fleet-roles">
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
            v-for="(privileges, group) in privilegeGroups"
            :key="group"
            class="privilege-group"
          >
            <h4 class="privilege-group-name">
              {{ t(`labels.fleet.roles.privilegeGroups.${group}`) }}
            </h4>
            <ul class="privilege-list">
              <li
                v-for="privilege in privileges"
                :key="privilege"
                class="privilege-item"
                :class="{
                  active: hasPrivilege(role, privilege),
                  implied: isImpliedByManage(role, privilege),
                }"
              >
                <i
                  :class="
                    hasPrivilege(role, privilege)
                      ? 'fa-solid fa-check text-success'
                      : isImpliedByManage(role, privilege)
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
