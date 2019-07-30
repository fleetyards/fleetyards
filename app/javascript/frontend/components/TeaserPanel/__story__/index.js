import { storiesOf } from '@storybook/vue'
import { withInfo } from 'storybook-addon-vue-info'
import { withKnobs, select } from '@storybook/addon-knobs'
import TeaserPanel from '../index'

const teaserVariants = {
  label: 'Variant',
  options: ['default', 'text'],
  default: 'default',
}

storiesOf('TeaserPanel', module)
  .addDecorator(withInfo)
  .addDecorator(withKnobs)
  .add('TeaserPanel', () => ({
    components: { TeaserPanel },
    props: {
      variant: {
        default: select(teaserVariants.label, teaserVariants.options, teaserVariants.default),
      },
    },
    template: `
      <TeaserPanel
        :item="{
          name: 'Galaxy Class',
          description: 'The Galaxy class is the result of an ambitious development program at Utopia Planitia Fleet Yards. It is the largest and most complex Starfleet starship built to date. The Galaxy class is primarily designed to replace the aged Ambassador and Oberth classes in research missions. Galaxy-class starships feature a detachable and independently operational saucer section, three shuttlebays and a captains yacht at the bottom of the saucer.',
          storeImageMedium: 'https://vignette.wikia.nocookie.net/memoryalpha/images/9/9d/USS_Enterprise-D.jpeg/revision/latest?cb=20131125162836&path-prefix=de',
        }"
        :variant="variant"
      />
    `,
  }))
