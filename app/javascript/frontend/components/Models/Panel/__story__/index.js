import { storiesOf } from '@storybook/vue'
import { withInfo } from 'storybook-addon-vue-info'
import StoryRouter from 'storybook-vue-router'
import { withKnobs, boolean, select } from '@storybook/addon-knobs'
import ModelPanel from '../index'

storiesOf('ModelPanel', module)
  .addDecorator(withInfo)
  .addDecorator(withKnobs)
  .addDecorator(StoryRouter())
  .add('ModelPanel', () => ({
    components: { ModelPanel },
    props: {
      vehicle: {
        default: {
          name: 'Foo',
        },
      },
      details: {
        default: boolean('Details', false),
      },
      count: {
        default: select('Count', [null, 1, 2, 3, 4, 5, 10, 100], null),
      },
      model: {
        default: {
          slug: 'galaxy-class',
          name: 'Galaxy Class',
          description: 'The Galaxy class is the result of an ambitious development program at Utopia Planitia Fleet Yards. It is the largest and most complex Starfleet starship built to date. The Galaxy class is primarily designed to replace the aged Ambassador and Oberth classes in research missions. Galaxy-class starships feature a detachable and independently operational saucer section, three shuttlebays and a captains yacht at the bottom of the saucer.',
          storeImageMedium: 'https://vignette.wikia.nocookie.net/memoryalpha/images/9/9d/USS_Enterprise-D.jpeg/revision/latest?cb=20131125162836&path-prefix=de',
          manufacturer: {
            slug: 'utopia-planitia',
            name: 'Utopia Planitia',
          },
          shipRole: {
            slug: 'exporation-cruiser',
            name: 'Exporation Cruiser',
          },
        },
      },
    },
    template: `
      <ModelPanel
        :model="model"
        :details="details"
        :count="count"
      />
    `,
  }))
