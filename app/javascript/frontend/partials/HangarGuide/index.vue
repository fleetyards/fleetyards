<template>
  <div class="hangar-guide">
    <h1>
      {{ t('headlines.hangarGuide') }}
      <small>{{ t('sublines.hangarGuide.headline') }}</small>
    </h1>
    <h2>{{ t('sublines.hangarGuide.add') }}</h2>
    <div class="hangar-guide-topic">
      <img
        :src="require(`images/hangar-guide/add.gif`)"
        class="hangar-guide-gif"
        alt="add-guide"
      >
      <p v-html="t('texts.hangarGuide.add')" />
      <div class="hangar-guide-highlight">
        {{ t('texts.hangarGuide.icon') }}
        <i class="fal fa-bookmark" />
      </div>
      <div class="clearfix" />
    </div>
    <hr>
    <h2>{{ t('sublines.hangarGuide.edit') }}</h2>
    <div class="hangar-guide-topic">
      <img
        :src="require(`images/hangar-guide/edit.gif`)"
        class="hangar-guide-gif"
        alt="edit-guide"
      >
      <p v-html="t('texts.hangarGuide.edit')" />
      <div class="hangar-guide-highlight">
        {{ t('texts.hangarGuide.icon') }}
        <i class="fa fa-pencil" />
      </div>
      <div class="clearfix" />
    </div>
    <hr>
    <h2>{{ t('sublines.hangarGuide.public') }}</h2>
    <div class="hangar-guide-topic">
      <img
        :src="require(`images/hangar-guide/public.gif`)"
        class="hangar-guide-gif"
        alt="public-guide"
      >
      <p v-html="t('texts.hangarGuide.public')" />
      <div class="clearfix" />
    </div>
    <hr>
    <h2>{{ t('sublines.hangarGuide.fleetchart') }}</h2>
    <div class="hangar-guide-topic">
      <img
        :src="require(`images/hangar-guide/fleetchart.gif`)"
        class="hangar-guide-gif"
        alt="fleetchart-guide"
      >
      <p v-html="t('texts.hangarGuide.fleetchart')" />
      <div class="clearfix" />
    </div>
    <hr>
    <h2>{{ t('sublines.hangarGuide.groups') }}</h2>
    <div class="hangar-guide-topic">
      <img
        :src="require(`images/hangar-guide/groups.gif`)"
        class="hangar-guide-gif"
        alt="groups-guide"
      >
      <p v-html="t('texts.hangarGuide.groups.add')" />
      <p v-html="t('texts.hangarGuide.groups.edit')" />
      <div class="clearfix" />
    </div>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'

export default {
  mixins: [I18n],
}
</script>

<style lang="scss" scoped>
  @import './styles/index';
</style>
