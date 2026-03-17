<script lang="ts">
export default {
  name: "SettingsOauthApplicationsList",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import ListGroup from "@/shared/components/ListGroup/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import {
  useOauthApplications,
  getOauthApplicationsQueryKey,
  destroyOauthApplication,
  type OauthApplication,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();

const { data: applications, isLoading } = useOauthApplications();

const items = computed<OauthApplication[]>(() => applications.value ?? []);

const invalidateOauthApplications = () =>
  queryClient.invalidateQueries({
    queryKey: getOauthApplicationsQueryKey(),
  });

const confirmDestroy = (app: OauthApplication) => {
  displayConfirm({
    text: t("messages.confirm.oauthApplication.destroy"),
    onConfirm: async () => {
      try {
        await destroyOauthApplication(app.id);
        void invalidateOauthApplications();
        displaySuccess({
          text: t("messages.oauthApplications.destroy.success"),
        });
      } catch {
        displayAlert({
          text: t("messages.oauthApplications.destroy.error"),
        });
      }
    },
  });
};

const formatScopes = (scopes: string) => {
  if (!scopes) return t("labels.oauthApplications.defaultScopes");
  return scopes.split(" ").filter(Boolean).join(", ");
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'settings' }, label: t('nav.settings.index') }]"
  />

  <div class="oauth-header">
    <div>
      <h1>{{ t("headlines.settings.oauthApplications") }}</h1>
      <p class="oauth-intro">
        {{ t("labels.oauthApplications.settingsIntro") }}
      </p>
    </div>
    <Btn
      :size="BtnSizesEnum.SMALL"
      :to="{ name: 'settings-oauth-application-create' }"
    >
      <i class="fa-duotone fa-plus" />
      {{ t("actions.oauthApplications.create") }}
    </Btn>
  </div>

  <ListGroup :items="items" :loading="isLoading" empty-name="oauthApplications">
    <template #display="{ item }">
      <div class="oauth-app-info">
        <router-link
          class="oauth-app-name"
          :to="{ name: 'settings-oauth-application', params: { id: item.id } }"
        >
          {{ item.name }}
        </router-link>
        <div class="oauth-app-meta">
          <span class="oauth-app-meta-item">
            <span class="oauth-app-meta-label">
              {{ t("labels.oauthApplications.clientId") }}:
            </span>
            <code>{{ item.uid }}</code>
          </span>
          <span class="oauth-app-meta-item">
            <i
              :class="
                item.confidential
                  ? 'fa-duotone fa-lock'
                  : 'fa-duotone fa-lock-open'
              "
            />
            {{
              item.confidential
                ? t("labels.oauthApplications.confidentialShort")
                : t("labels.oauthApplications.publicShort")
            }}
          </span>
          <span v-if="item.scopes" class="oauth-app-meta-item">
            {{ formatScopes(item.scopes) }}
          </span>
        </div>
      </div>
    </template>

    <template #actions="{ item }">
      <BtnGroup inline>
        <Btn
          :size="BtnSizesEnum.SMALL"
          :to="{
            name: 'settings-oauth-application-edit',
            params: { id: item.id },
          }"
        >
          <i class="fa-duotone fa-pencil" />
        </Btn>
        <Btn
          :size="BtnSizesEnum.SMALL"
          :variant="BtnVariantsEnum.DANGER"
          @click="confirmDestroy(item)"
        >
          <i class="fa-duotone fa-trash" />
        </Btn>
      </BtnGroup>
    </template>
  </ListGroup>
</template>

<style lang="scss" scoped>
.oauth-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
  margin-bottom: 1rem;

  h1 {
    margin-bottom: 0.25rem;
  }
}

.oauth-intro {
  margin-bottom: 0;
  color: var(--text-muted);
}

.oauth-app-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  min-width: 0;
}

.oauth-app-name {
  font-weight: 600;
}

.oauth-app-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  font-size: 0.85rem;
  color: var(--text-muted);
}

.oauth-app-meta-item {
  display: flex;
  align-items: center;
  gap: 0.25rem;

  code {
    font-size: 0.8rem;
  }
}

.oauth-app-meta-label {
  font-weight: 600;
}
</style>
