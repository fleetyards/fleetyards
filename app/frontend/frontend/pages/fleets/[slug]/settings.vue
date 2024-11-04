<template>
  <div class="row">
    <div class="col-12 col-md-3 order-md-12">
      <ul class="tabs">
        <router-link
          v-if="canEdit"
          v-slot="{ href: linkHref, navigate }"
          :to="{ name: 'fleet-settings-fleet' }"
          :custom="true"
        >
          <li role="link" @click="navigate" @keypress.enter="() => navigate()">
            <a :href="linkHref">{{ t("nav.fleets.settings.fleet") }}</a>
          </li>
        </router-link>

        <router-link
          v-slot="{ href: linkHref, navigate }"
          :to="{ name: 'fleet-settings-membership' }"
          :custom="true"
        >
          <li role="link" @click="navigate" @keypress.enter="() => navigate()">
            <a :href="linkHref">{{ t("nav.fleets.settings.membership") }}</a>
          </li>
        </router-link>
        <li
          v-if="fleet"
          v-tooltip="leaveTooltip"
          :class="{
            disabled: canEdit || leaving,
          }"
        >
          <a @click="leave">
            <i class="fal fa-sign-out" />
            {{ t("actions.fleet.leave", { fleet: fleet.name }) }}
          </a>
        </li>
      </ul>
    </div>
    <div class="col-12 col-md-9 order-md-1">
      <router-view :fleet="fleet" />
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useComlink } from "@/shared/composables/useComlink";
import { type Fleet } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";

const { t } = useI18n();

const { displayAlert, displayConfirm, displaySuccess } = useNoty();

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const leaving = ref(false);

const leaveTooltip = computed(() => {
  if (props.fleet.myFleet && props.fleet.myRole === "admin") {
    return t("texts.fleets.leaveInfo");
  }

  return null;
});

const canEdit = computed(() => {
  return props.fleet?.myRole === "admin";
});

const comlink = useComlink();

const router = useRouter();

const leave = () => {
  if (!canEdit.value || leaving.value) return;

  leaving.value = true;

  displayConfirm({
    text: t("messages.confirm.fleet.leave"),
    onConfirm: async () => {
      const response = await this.$api.destroy(
        `fleets/${props.fleet.slug}/members/leave`,
      );

      leaving.value = false;

      if (!response.error) {
        comlink.emit("fleet-update");

        displaySuccess({
          text: t("messages.fleet.leave.success"),
        });

        // eslint-disable-next-line @typescript-eslint/no-empty-function
        router.push({ name: "home" }).catch(() => {});
      } else {
        const { error } = response;
        if (error.response && error.response.data) {
          const { data: errorData } = error.response;

          displayAlert({
            text: errorData.message,
          });
        } else {
          displayAlert({
            text: t("messages.fleet.leave.failure"),
          });
        }
      }
    },
    onClose: () => {
      leaving.value = false;
    },
  });
};
</script>

<script lang="ts">
export default {
  name: "FleetSettingsRouterView",
};
</script>
