import { storiesOf } from '@storybook/vue'
import { withInfo } from 'storybook-addon-vue-info'
import {
  withKnobs, text, boolean, select,
} from '@storybook/addon-knobs'
import notes from './notes.md'
import Btn from '../index'

const info = {
  // https://github.com/pocka/storybook-addon-vue-info
}

const buttonVariants = {
  label: 'Variant',
  options: ['default', 'danger', 'link', 'transparent'],
  default: 'default',
}

const buttonSizes = {
  label: 'Size',
  options: ['default', 'small', 'large'],
  default: 'default',
}

storiesOf('Btn', module)
  .addDecorator(withInfo)
  .addDecorator(withKnobs)
  .add('Btn', () => ({
    components: { Btn },
    props: {
      loading: {
        default: boolean('Loading', false),
      },
      variant: {
        default: select(buttonVariants.label, buttonVariants.options, buttonVariants.default),
      },
      size: {
        default: select(buttonSizes.label, buttonSizes.options, buttonSizes.default),
      },
      block: {
        default: boolean('Block', false),
      },
      mobileBlock: {
        default: boolean('Mobile Block', false),
      },
      active: {
        default: boolean('Active', false),
      },
      disabled: {
        default: boolean('Disabled', false),
      },
      inline: {
        default: boolean('Inline', false),
      },
    },
    template: `
      <Btn
        :loading="loading"
        :variant="variant"
        :size="size"
        :block="block"
        :mobileBlock="mobileBlock"
        :active="active"
        :disabled="disabled"
        :inline="inline"
      >
        ${text('Label', 'Test Button')}
      </Btn>
    `,
  }), { notes, info })
