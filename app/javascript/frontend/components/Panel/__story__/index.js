import { storiesOf } from '@storybook/vue'
import { withInfo } from 'storybook-addon-vue-info'
import { withKnobs, text, boolean } from '@storybook/addon-knobs'
import Panel from '../index'

const info = {
  // https://github.com/pocka/storybook-addon-vue-info
}

storiesOf('Panel', module)
  .addDecorator(withInfo)
  .addDecorator(withKnobs)
  .add('Panel', () => ({
    components: { Panel },
    props: {
      outerSpacing: {
        default: boolean('Outer Spacing', false),
      },
    },
    template: `
      <Panel
        :outer-spacing="outerSpacing"
      >
        <div style="padding: 60px;">${text('Content', 'Test Content')}</div>
      </Panel>
    `,
  }), { info })
