<script lang="ts">
export default {
  name: "FleetInvitePage",
};
</script>

<script lang="ts" setup>
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import { useFleetStore } from "@/frontend/stores/fleet";
import {
  useUseFleetInvite as useUseFleetInviteMutation,
  findFleetByInvite,
} from "@/services/fyApi";

const { t } = useI18n();

const { displayAlert, displaySuccess } = useAppNotifications();

const fleetStore = useFleetStore();

onMounted(() => {
  useInvite();
});

const route = useRoute();

const router = useRouter();

const inviteToken = computed(() => route.params.token as string);

const useInvite = async () => {
  await findFleetByInvite(inviteToken.value)
    .then((fleet) => {
      displayConfirm({
        text: t("messages.fleetInvite.confirm", {
          fleet: fleet.name,
        }),
        onConfirm: () => {
          handleFleetInvite();
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
    .catch(async (error) => {
      console.error(error);

      displayAlert({
        text: t("messages.fleetInvite.notFound"),
      });

      await router
        .push({
          name: "home",
        })
        .catch(() => {});
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
          name: "fleet",
          params: { slug: member.fleetSlug },
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
  <section class="container fleet-detail" />
</template>
