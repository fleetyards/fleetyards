import { storiesOf } from '@storybook/vue'
import { withInfo } from 'storybook-addon-vue-info'
import { withKnobs, boolean } from '@storybook/addon-knobs'
import Loader from '../index'

storiesOf('Loader', module)
  .addDecorator(withInfo)
  .addDecorator(withKnobs)
  .add('Loader', () => ({
    components: { Loader },
    props: {
      loading: {
        default: boolean('Loading', true),
      },
      fixed: {
        default: boolean('Fixed', false),
      },
    },
    template: `
      <Loader
        :fixed="fixed"
        :loading="loading"
      />
    `,
  }))
