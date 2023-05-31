<template>
  <section class="container">
    <div class="row">
      <div class="col-12 col-md-3 order-md-12">
        <ul class="tabs">
          <router-link
            v-if="canEdit"
            v-slot="{ href: linkHref, navigate }"
            :to="{ name: 'fleet-settings-fleet' }"
            :custom="true"
          >
            <li role="link" @click="navigate" @keypress.enter="navigate">
              <a :href="linkHref">{{ $t("nav.fleets.settings.fleet") }}</a>
            </li>
          </router-link>

          <router-link
            v-slot="{ href: linkHref, navigate }"
            :to="{ name: 'fleet-settings-membership' }"
            :custom="true"
          >
            <li role="link" @click="navigate" @keypress.enter="navigate">
              <a :href="linkHref">{{ $t("nav.fleets.settings.membership") }}</a>
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
              {{ $t("actions.fleet.leave", { fleet: fleet.name }) }}
            </a>
          </li>
        </ul>
      </div>
      <div class="col-12 col-md-9 order-md-1">
        <router-view />
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { ref, computed, watch, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import {
  displaySuccess,
  displayAlert,
  displayConfirm,
} from "@/frontend/lib/Noty";
import fleetsCollection from "@/frontend/api/collections/Fleets";
import type { FleetsCollection } from "@/frontend/api/collections/Fleets";
import fleetMembersCollection from "@/frontend/api/collections/FleetMembers";
import type { FleetMembersCollection } from "@/frontend/api/collections/FleetMembers";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/frontend/composables/useComlink";
import { ApiErrorResponse } from "@/frontend/api/client";

const leaving = ref(false);

const collection: FleetsCollection = fleetsCollection;
const membersCollection: FleetMembersCollection = fleetMembersCollection;

const fleet = computed<Fleet | null>(() => collection.record);

const { t } = useI18n();

const leaveTooltip = computed(() => {
  if (fleet.value?.myFleet && fleet.value?.myRole === "admin") {
    return t("texts.fleets.leaveInfo");
  }

  return null;
});

const canEdit = computed<boolean>(() => fleet.value?.myRole === "admin");
const myFleet = computed<boolean>(() => !!fleet.value?.myFleet);

const route = useRoute();

const fetch = async () => {
  await collection.findBySlug(route.params.slug);
};

watch(
  () => route,
  () => {
    fetch();
  },
  { deep: true }
);

const comlink = useComlink();

onMounted(() => {
  fetch();
  comlink.$on("fleet-update", fetch);
});

const router = useRouter();

const leave = async () => {
  if (!fleet.value) return;

  if ((myFleet.value && fleet.value.myRole === "admin") || leaving.value)
    return;

  leaving.value = true;

  displayConfirm({
    text: t("messages.confirm.fleet.leave"),
    onConfirm: async () => {
      if (!fleet.value) return;

      const response = await membersCollection.leave(fleet.value.slug);

      leaving.value = false;

      if (!response.error) {
        comlink.$emit("fleet-update");

        displaySuccess({
          text: t("messages.fleet.leave.success"),
        });

        router.push({ name: "home" }).catch(() => {
          // Ignore
        });
      } else {
        const { error } = response as ApiErrorResponse;

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
  name: "FleetSettingsPage",
};
</script>
