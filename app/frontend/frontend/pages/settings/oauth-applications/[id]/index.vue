<script lang="ts">
export default {
  name: "SettingsOauthApplicationDetail",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import {
  BtnVariantsEnum,
  BtnSizesEnum,
} from "@/shared/components/base/Btn/types";
import {
  type OauthApplication,
  getOauthApplicationsQueryKey,
  getOauthApplicationQueryKey,
  destroyOauthApplication,
  regenerateOauthApplicationSecret,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  oauthApplication: OauthApplication;
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();

const visibleSecret = ref<string | null>(
  (route.query.secret as string) || null,
);

const redirectUris = computed(() =>
  props.oauthApplication.redirectUri
    .split("\n")
    .map((uri) => uri.trim())
    .filter(Boolean),
);

const scopes = computed(() =>
  props.oauthApplication.scopes
    ? props.oauthApplication.scopes.split(" ").filter(Boolean)
    : [],
);

const invalidate = () => {
  void Promise.all([
    queryClient.invalidateQueries({
      queryKey: getOauthApplicationsQueryKey(),
    }),
    queryClient.invalidateQueries({
      queryKey: getOauthApplicationQueryKey(props.oauthApplication.id),
    }),
  ]);
};

const copyToClipboard = async (text: string) => {
  try {
    await navigator.clipboard.writeText(text);
    displaySuccess({ text: t("messages.oauthApplications.copied") });
  } catch {
    displayAlert({ text: t("messages.oauthApplications.copyError") });
  }
};

const confirmRegenerateSecret = () => {
  displayConfirm({
    text: t("messages.confirm.oauthApplication.regenerateSecret"),
    onConfirm: async () => {
      try {
        const result = await regenerateOauthApplicationSecret(
          props.oauthApplication.id,
        );
        invalidate();
        visibleSecret.value = result.secret;
        displaySuccess({
          text: t("messages.oauthApplications.regenerateSecret.success"),
        });
      } catch {
        displayAlert({
          text: t("messages.oauthApplications.regenerateSecret.error"),
        });
      }
    },
  });
};

const dismissSecret = async () => {
  visibleSecret.value = null;
  await router.replace({
    query: {},
  });
};

const confirmDestroy = () => {
  displayConfirm({
    text: t("messages.confirm.oauthApplication.destroy"),
    onConfirm: async () => {
      try {
        await destroyOauthApplication(props.oauthApplication.id);
        void queryClient.invalidateQueries({
          queryKey: getOauthApplicationsQueryKey(),
        });
        displaySuccess({
          text: t("messages.oauthApplications.destroy.success"),
        });
        await router.push({ name: "settings-oauth-applications" });
      } catch {
        displayAlert({
          text: t("messages.oauthApplications.destroy.error"),
        });
      }
    },
  });
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      { to: { name: 'settings' }, label: t('nav.settings.index') },
      {
        to: { name: 'settings-oauth-applications' },
        label: t('nav.settings.oauthApplications'),
      },
    ]"
  />

  <div class="oauth-detail-header">
    <h1>{{ oauthApplication.name }}</h1>
    <BtnGroup inline>
      <Btn
        :size="BtnSizesEnum.SMALL"
        :to="{
          name: 'settings-oauth-application-edit',
          params: { id: oauthApplication.id },
        }"
      >
        <i class="fa-duotone fa-pencil" />
        {{ t("actions.edit") }}
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.DANGER"
        @click="confirmDestroy"
      >
        <i class="fa-duotone fa-trash" />
        {{ t("actions.delete") }}
      </Btn>
    </BtnGroup>
  </div>

  <div v-if="visibleSecret" class="oauth-secret-banner">
    <div class="oauth-secret-banner-header">
      <strong>{{ t("labels.oauthApplications.clientSecret") }}</strong>
      <Btn
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.LINK"
        @click="dismissSecret"
        inline
      >
        <i class="fa-duotone fa-times" />
      </Btn>
    </div>
    <p class="oauth-secret-warning">
      {{ t("messages.oauthApplications.secretWarning") }}
    </p>
    <div class="oauth-detail-value">
      <code>{{ visibleSecret }}</code>
      <Btn
        :size="BtnSizesEnum.SMALL"
        @click="copyToClipboard(visibleSecret)"
        inline
      >
        <i class="fa-duotone fa-copy" />
      </Btn>
    </div>
  </div>

  <div class="oauth-details">
    <div class="oauth-detail">
      <span class="oauth-detail-label">{{
        t("labels.oauthApplications.clientId")
      }}</span>
      <div class="oauth-detail-value">
        <code>{{ oauthApplication.uid }}</code>
        <Btn
          :size="BtnSizesEnum.SMALL"
          @click="copyToClipboard(oauthApplication.uid)"
          inline
        >
          <i class="fa-duotone fa-copy" />
        </Btn>
      </div>
    </div>

    <div class="oauth-detail">
      <span class="oauth-detail-label">{{
        t("labels.oauthApplications.clientSecret")
      }}</span>
      <div class="oauth-detail-value">
        <Btn :size="BtnSizesEnum.SMALL" @click="confirmRegenerateSecret">
          <i class="fa-duotone fa-rotate" />
          {{ t("actions.oauthApplications.regenerateSecret") }}
        </Btn>
      </div>
    </div>

    <div class="oauth-detail">
      <span class="oauth-detail-label">{{
        t("labels.oauthApplications.redirectUri")
      }}</span>
      <div v-for="uri in redirectUris" :key="uri" class="oauth-detail-value">
        <code>{{ uri }}</code>
        <Btn :size="BtnSizesEnum.SMALL" @click="copyToClipboard(uri)" inline>
          <i class="fa-duotone fa-copy" />
        </Btn>
      </div>
    </div>

    <div class="oauth-detail">
      <span class="oauth-detail-label">{{
        t("labels.oauthApplications.scopes")
      }}</span>
      <div v-if="scopes.length" class="oauth-scopes">
        <code v-for="scope in scopes" :key="scope" class="oauth-scope">
          {{ scope }}
        </code>
      </div>
      <div v-else class="oauth-detail-value">
        <code>{{ t("labels.oauthApplications.defaultScopes") }}</code>
      </div>
    </div>

    <div class="oauth-detail">
      <span class="oauth-detail-label">{{
        t("labels.oauthApplications.confidential")
      }}</span>
      <div class="oauth-detail-value">
        {{
          oauthApplication.confidential ? t("labels.true") : t("labels.false")
        }}
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.oauth-detail-header {
  display: flex;
  align-items: center;
  justify-content: space-between;

  h1 {
    margin-bottom: 0;
  }
}

.oauth-secret-banner {
  margin-top: 1.5rem;
  padding: 1rem;
  border: 1px solid rgba(#4caf50, 0.4);
  border-radius: 0.5rem;
  background: rgba(#4caf50, 0.05);
}

.oauth-secret-banner-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0.5rem;
}

.oauth-secret-warning {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin-bottom: 0.5rem;
}

.oauth-details {
  margin-top: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.oauth-detail {
  > .oauth-detail-label {
    display: block;
    font-size: 0.85rem;
    font-weight: 600;
    color: var(--text-muted);
    margin-bottom: 0.25rem;
  }
}

.oauth-detail-value {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.25rem;

  code {
    padding: 0.25rem 0.5rem;
    background: var(--bg-secondary, rgba(0, 0, 0, 0.1));
    border-radius: 0.25rem;
    font-size: 0.85rem;
    word-break: break-all;
  }
}

.oauth-scopes {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.oauth-scope {
  padding: 0.25rem 0.5rem;
  background: var(--bg-secondary, rgba(0, 0, 0, 0.1));
  border-radius: 0.25rem;
  font-size: 0.85rem;
}
</style>
