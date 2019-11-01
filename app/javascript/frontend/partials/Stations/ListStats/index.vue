<template>
  <dl
    v-if="station"
    class="dl-horizontal"
  >
    <dt>{{ $t('labels.station.type') }}:</dt>
    <dd>{{ station.typeLabel }}</dd>

    <dt>{{ $t('labels.station.location') }}:</dt>
    <dd>{{ station.locationLabel }}</dd>

    <dt v-if="station.shopsListLabel">
      {{ $t('labels.station.shops') }}:
    </dt>
    <dd v-if="station.shopsListLabel">
      {{ station.shopListLabel }}
    </dd>

    <template v-if="station.dockCounts.length">
      <dt>{{ $t('labels.station.docks') }}:</dt>
      <dd>
        <ul class="list-unstyled">
          <li
            v-for="(dock, index) in station.dockCounts"
            :key="index"
          >
            {{ dock.size }} {{ dock.typeLabel }}: {{ dock.count }}
          </li>
        </ul>
      </dd>
    </template>

    <template v-if="station.habitationCounts.length">
      <dt>{{ $t('labels.station.habitation') }}:</dt>
      <dd>
        <ul class="list-unstyled">
          <li
            v-for="(habitation, index) in station.habitationCounts"
            :key="index"
          >
            {{ habitation.typeLabel }}: {{ habitation.count }}
          </li>
        </ul>
      </dd>
    </template>
  </dl>
</template>

<script>
export default {
  props: {
    station: {
      type: Object,
      required: true,
    },
  },
}
</script>
