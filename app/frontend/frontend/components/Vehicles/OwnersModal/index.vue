<template>
  <Modal :title="t('headlines.fleets.owners')">
    <div class="row">
      <div v-if="loading" class="col-12">
        <Loader :loading="loading" :inline="true" />
      </div>
      <template v-else>
        <div
          v-for="vehicle in sortedVehicles"
          :key="vehicle.username"
          class="col-12 col-md-6"
        >
          <Btn
            v-if="vehicle.username"
            :href="`/hangar/${vehicle.username}`"
            :block="true"
          >
            <div class="user-item">
              <Avatar :avatar="vehicle.userAvatar" size="small" />
              <span class="user-item-username">
                {{ vehicle.username }}
                <span v-if="vehicle.name" class="user-item-ship">
                  {{ vehicle.name }}
                  <span v-if="vehicle.serial" class="user-item-ship-serial">
                    ({{ vehicle.serial }})
                  </span>
                </span>
              </span>
            </div>
          </Btn>
          <Btn v-else :disabled="true" :block="true">
            <div class="user-item">
              <Avatar size="small" />
              <span class="user-item-username">
                {{ t("labels.anonymous") }}
                <span v-if="vehicle.name" class="user-item-ship">
                  {{ vehicle.name }}
                  <span v-if="vehicle.serial" class="user-item-ship-serial">
                    ({{ vehicle.serial }})
                  </span>
                </span>
              </span>
            </div>
          </Btn>
        </div>
      </template>
    </div>
  </Modal>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import Btn from "@/shared/components/base/Btn/index.vue";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";
import Avatar from "@/frontend/core/components/Avatar/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { sortBy, uniqByField as uniqByFieldArray } from "@/shared/utils/Array";
import { type VehiclePublic } from "@/services/fyApi";
// import { FleetVehiclesCollection } from "@/frontend/api/collections/FleetVehicles";

type Props = {
  modelSlug: string;
  fleetSlug: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

// const collection: FleetVehiclesCollection = new FleetVehiclesCollection();

const loading = ref(true);

const sortedVehicles = computed(() =>
  // sortBy(collection.records, "username").filter(uniqByFieldArray("username")),
  sortBy([] as VehiclePublic[], "username").filter(
    uniqByFieldArray("username"),
  ),
);

const route = useRoute();

// const query = computed(() => (route.query.q || {}) as VehiclesFilter);

// const loanerEq = computed(() => query.value.loanerEq as boolean | "only");

onMounted(async () => {
  // await collection.findAll({
  //   slug: props.fleetSlug,
  //   filters: { modelSlugIn: [props.modelSlug], loanerEq: loanerEq.value },
  //   grouped: false,
  //   perPage: "all",
  // });

  loading.value = false;
});
</script>

<script lang="ts">
export default {
  name: "VehicleOwnersModal",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
