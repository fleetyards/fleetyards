<script lang="ts">
export default {
  name: "ConfirmAccountPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useRoute, useRouter } from "vue-router";
import { useConfirmAccount as useConfirmAccountMutation } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useHangarStore } from "@/frontend/stores/hangar";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const hangarStore = useHangarStore();

const mutation = useConfirmAccountMutation();

onMounted(() => {
  confirmAccount();
});

const route = useRoute();

const router = useRouter();

const comlink = useComlink();

const confirmAccount = async () => {
  await mutation
    .mutateAsync({
      data: {
        token: route.params.token as string,
      },
    })
    .then(() => {
      comlink.emit("user-update");

      displaySuccess({
        text: t("messages.accountConfirm.success"),
      });

      hangarStore.enableStarterGuide();
    })
    .catch((error) => {
      console.error(error);

      displayAlert({
        text: t("messages.accountConfirm.failure"),
      });
    })
    .finally(async () => {
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      await router.push("/").catch(() => {});
    });
};
</script>
