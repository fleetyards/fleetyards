<template>
  <div>
    <div class="row compare-row compare-section">
      <div class="col-xs-12 compare-row-label">
        <div
          :class="{
            active: visible,
          }"
          class="text-right metrics-title"
          @click="toggle"
        >
          {{ $t('labels.hardpoint.legend.headline') }}
          <i class="fa fa-chevron-right" />
        </div>
      </div>
      <div
        v-for="model in models"
        :key="`${model.slug}-placeholder`"
        class="col-xs-12 compare-row-item"
      />
    </div>
    <BCollapse id="legend" :visible="visible">
      <div class="row compare-row">
        <div class="col-xs-12 compare-row-label text-right metrics-label" />
        <div
          v-for="(model, index) in models"
          :key="`${model.slug}-legend`"
          class="col-xs-6 text-center compare-row-item"
        >
          <Panel v-if="index === 0">
            <div class="hardpoint-category hardpoint-legend">
              <div class="row">
                <div class="col-xs-12 col-md-6 test-hardpoint">
                  <h3>{{ $t('labels.hardpoint.legend.slotTaken') }}</h3>
                  <HardpointIcon
                    key="testHardpoint"
                    :hardpoint="testHardpoint"
                    style="float: left;"
                  />
                  <div style="float: left;" class="hardpoint-labels">
                    <div class="hardpoint-quantity">
                      - {{ $t('labels.hardpoint.quantity') }}
                    </div>
                    <div class="hardpoint-size">
                      - {{ $t('labels.hardpoint.size') }}
                    </div>
                  </div>
                </div>
                <div class="col-xs-12 col-md-6 test-hardpoint-empty">
                  <h3>{{ $t('labels.hardpoint.legend.slotAvailable') }}</h3>
                  <HardpointIcon
                    key="testHardpointEmpty"
                    :hardpoint="testHardpointEmpty"
                    style="float: left;"
                  />
                  <div style="float: left;" class="hardpoint-labels">
                    <div class="hardpoint-quantity">
                      - {{ $t('labels.hardpoint.quantity') }}
                    </div>
                    <div class="hardpoint-size">
                      - {{ $t('labels.hardpoint.size') }}
                    </div>
                  </div>
                </div>
                <div class="col-xs-12 hardpoint-legend-additions">
                  <div class="hardpoint-legend-addition">
                    <div class="hardpoint-icon">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 47.98 55.4"
                      >
                        <polygon
                          class="hardpoint-icon-part hardpoint-icon-category"
                          points="14,0 7,0 3.5,6.1 7,12.1 14,12.1 17.5,6.1"
                        />
                      </svg>
                      <div class="hardpoint-label hardpoint-category-label">
                        V
                      </div>
                    </div>
                    <div class="hardpoint-labels">
                      {{ $t('labels.hardpoint.categoryOrRackSize') }}
                    </div>
                  </div>
                  <div class="hardpoint-legend-addition">
                    <div class="hardpoint-icon hardpoint-icon-legend-mounts ">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 47.98 55.4"
                      >
                        <circle
                          class="hardpoint-icon-part hardpoint-icon-mounts"
                          cx="37.5"
                          cy="6.38"
                          r="6.38"
                        />
                      </svg>
                      <div class="hardpoint-label hardpoint-mounts-label">
                        2
                      </div>
                    </div>
                    <div class="hardpoint-labels">
                      {{ $t('labels.hardpoint.mounts') }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </Panel>
        </div>
      </div>
    </BCollapse>
  </div>
</template>

<script>
import { BCollapse } from 'bootstrap-vue'
import Panel from 'frontend/components/Panel'
import HardpointIcon from 'frontend/partials/Models/Hardpoints/Icon'

export default {
  components: {
    BCollapse,
    HardpointIcon,
    Panel,
  },
  props: {
    models: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      visible: this.models.length > 0,
      testHardpoint: {
        size: 'S',
        quantity: 6,
      },
      testHardpointEmpty: {
        size: 'S',
        quantity: 6,
        defaultEmpty: true,
      },
    }
  },
  watch: {
    models() {
      this.visible = this.models.length > 0
    },
  },
  methods: {
    toggle() {
      this.visible = !this.visible
    },
  },
}
</script>
