<script lang="ts">
export default {
  name: "RelationshipsFriendButton",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { type BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useSessionStore } from "@/frontend/stores/session";
import {
  FeatureFlagName,
  useAcceptFriendship,
  useCreateFriendship,
  useFriendship,
} from "@/services/fyApi";

type Props = {
  username: string;
  size?: `${BtnSizesEnum}`;
};

const props = withDefaults(defineProps<Props>(), { size: undefined });

const { t } = useI18n();
const { displayAlert, displaySuccess } = useAppNotifications();
const { isFeatureEnabled } = useFeatures();
const sessionStore = useSessionStore();

const username = computed(() => props.username);

const reader = computed(() => sessionStore.currentUser?.username);

// Nobody asks themselves, and a reader who is not signed in has no username to
// ask with.
const enabled = computed(
  () =>
    !!reader.value &&
    isFeatureEnabled(FeatureFlagName.FRIENDS) &&
    reader.value.toLowerCase() !== props.username.toLowerCase(),
);

const query = useFriendship(username, {
  query: { enabled, retry: false },
});

// A 404 is the answer "there is no relationship", which is the state the button
// exists for -- so the error is the common case here rather than a failure.
const mode = computed(() => {
  if (!enabled.value || query.isLoading.value) {
    return undefined;
  }

  const friendship = query.data.value;

  if (!friendship || friendship.state === "declined") {
    return "add";
  }

  // Only the party who ignored a request ever reads `ignored`, and offering
  // them a button that silently goes nowhere is worse than offering none.
  if (friendship.state === "ignored") {
    return undefined;
  }

  if (friendship.state === "accepted") {
    return "friends";
  }

  return friendship.direction === "incoming" ? "accept" : "sent";
});

const createMutation = useCreateFriendship();
const acceptMutation = useAcceptFriendship();

const busy = ref(false);

const run = async (action: () => Promise<unknown>, successKey: string) => {
  busy.value = true;

  try {
    await action();
    displaySuccess({ text: t(`messages.friends.${successKey}.success`) });
  } catch {
    displayAlert({ text: t(`messages.friends.${successKey}.failure`) });
  } finally {
    await query.refetch();
    busy.value = false;
  }
};

const add = () =>
  run(
    () => createMutation.mutateAsync({ data: { username: props.username } }),
    "request",
  );

const accept = () =>
  run(() => acceptMutation.mutateAsync({ username: props.username }), "accept");
</script>

<template>
  <Btn
    v-if="mode === 'add'"
    :size="props.size"
    :loading="busy"
    data-test="friend-add"
    @click="add"
  >
    <i class="fa-duotone fa-user-plus" />
    {{ t("actions.relationships.user.add") }}
  </Btn>

  <Btn
    v-else-if="mode === 'accept'"
    :size="props.size"
    :loading="busy"
    data-test="friend-accept"
    @click="accept"
  >
    <i class="fa-duotone fa-user-check" />
    {{ t("actions.relationships.accept") }}
  </Btn>

  <Btn
    v-else-if="mode === 'sent'"
    :size="props.size"
    disabled
    data-test="friend-requested"
  >
    <i class="fa-duotone fa-hourglass-half" />
    {{ t("labels.relationships.requested") }}
  </Btn>

  <Btn
    v-else-if="mode === 'friends'"
    :size="props.size"
    disabled
    data-test="friend-accepted"
  >
    <i class="fa-duotone fa-user-group" />
    {{ t("labels.relationships.friend") }}
  </Btn>
</template>
