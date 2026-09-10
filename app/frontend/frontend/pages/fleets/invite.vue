<script lang="ts">
export default {
  name: "FleetInvitePage",
};
</script>

<script lang="ts" setup>
import InviteInvalid from "@/shared/components/InviteInvalid/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import { useFleetStore } from "@/frontend/stores/fleet";
import {
  useUseFleetInvite as useUseFleetInviteMutation,
  findFleetByInvite,
} from "@/services/fyApi";

const { t } = useI18n();

const { displayAlert, displaySuccess, displayConfirm } = useAppNotifications();

const fleetStore = useFleetStore();

onMounted(async () => {
  await useInvite();
});

const route = useRoute();

const router = useRouter();

const inviteToken = computed(() => route.params.token as string);

// The lookup failing is a property of the link itself, so it stays on the page
// rather than becoming a toast the reader is redirected away from. Redeeming a
// valid invite can fail transiently, which is why only this half is a state.
const inviteInvalid = ref(false);

const useInvite = async () => {
  await findFleetByInvite(inviteToken.value)
    .then((fleet) => {
      displayConfirm({
        text: t("messages.fleetInvite.confirm", {
          fleet: fleet.name,
        }),
        onConfirm: async () => {
          await handleFleetInvite();
        },
        onClose: async () => {
          await router
            .push({
              name: "home",
            })
            .catch(() => {});
        },
      });
    })
    .catch((error) => {
      console.error(error);

      inviteInvalid.value = true;
    });
};

const useInviteMutation = useUseFleetInviteMutation();

const handleFleetInvite = async () => {
  await useInviteMutation
    .mutateAsync({
      data: {
        token: inviteToken.value,
      },
    })
    .then(async (member) => {
      fleetStore.resetInviteToken();

      displaySuccess({
        text: t("messages.fleetInvite.used", { fleet: member.fleetName }),
      });

      await router
        .push({
          name: "home",
        })
        .catch(() => {});
    })
    .catch(async (error) => {
      console.error(error);

      displayAlert({
        text: t("messages.fleetInvite.failure"),
      });

      await router
        .push({
          name: "home",
        })
        .catch(() => {});
    });
};
</script>

<template>
  <section class="container fleet-detail">
    <InviteInvalid v-if="inviteInvalid" :token="inviteToken" />
  </section>
</template>
