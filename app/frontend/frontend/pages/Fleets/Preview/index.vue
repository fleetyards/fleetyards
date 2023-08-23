<template>
  <section class="container fleet">
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <h1 class="sr-only">
              {{ t("headlines.fleets.preview.h1") }}
            </h1>
          </div>
        </div>

        <div class="row">
          <div class="col-12">
            <h2 class="text-center main-headline">
              {{ t("headlines.fleets.preview.h2") }}
            </h2>
          </div>
        </div>

        <hr class="large-spacer" />

        <div class="row">
          <div class="col-12">
            <h3 class="text-center main-subheadline">
              {{ t("headlines.fleets.preview.h3") }}
            </h3>
          </div>
        </div>

        <br />

        <div class="row">
          <div class="col-12 col-lg-4">
            <Panel class="info-box" transparency="more">
              <div class="panel-heading">
                <h2 class="panel-title text-center">
                  {{ t("texts.fleetPreview.notified.headline") }}
                </h2>
              </div>
              <div class="panel-body text-center">
                <p v-html="t('texts.fleetPreview.notified.text')" />
              </div>
            </Panel>
          </div>
          <div class="col-12 col-lg-4">
            <Panel class="info-box" transparency="more">
              <div class="panel-heading">
                <h2 class="panel-title text-center">
                  {{ t("texts.fleetPreview.overview.headline") }}
                </h2>
              </div>
              <div class="panel-body text-center">
                <p v-html="t('texts.fleetPreview.overview.text')" />
              </div>
            </Panel>
          </div>
          <div class="col-12 col-lg-4">
            <Panel class="info-box" transparency="more">
              <div class="panel-heading">
                <h2 class="panel-title text-center">
                  {{ t("texts.fleetPreview.fleetchart.headline") }}
                </h2>
              </div>
              <div class="panel-body text-center">
                <p v-html="t('texts.fleetPreview.fleetchart.text')" />
              </div>
            </Panel>
          </div>
        </div>

        <hr class="large-spacer" />

        <div class="row justify-content-center">
          <div class="col-12 col-lg-4">
            <Btn
              :to="{
                name: 'signup',
                params: {
                  redirectToRoute: 'fleet-add',
                },
              }"
              data-test="signup"
              size="large"
              :block="true"
            >
              {{ t("actions.signUp") }}
            </Btn>

            <hr />

            <p class="text-center">
              {{ t("labels.alreadyRegistered") }}
            </p>

            <Btn
              v-if="fleetPreview"
              data-test="login"
              :block="true"
              @click="hidePreview"
            >
              {{ t("actions.login") }}
            </Btn>
            <Btn
              v-else
              :to="{
                name: 'login',
                params: {
                  redirectToRoute: 'fleet-add',
                },
              }"
              data-test="login"
              :block="true"
              @click="hidePreview"
            >
              {{ t("actions.login") }}
            </Btn>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/BaseBtn/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useFleetStore } from "@/frontend/stores/fleet";
import { storeToRefs } from "pinia";

const { t } = useI18n();

const router = useRouter();

const fleetStore = useFleetStore();

const { preview: fleetPreview } = storeToRefs(fleetStore);

const hidePreview = () => {
  fleetStore.preview = false;

  router.push({
    name: "login",
    params: {
      redirectToRoute: "fleet-add",
    },
  });
};
</script>

<script lang="ts">
export default {
  name: "FleetPreviewPage",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
