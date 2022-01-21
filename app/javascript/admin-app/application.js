import { Application } from '@hotwired/stimulus'
import BaseController from './controllers/base'
import DashboardController from './controllers/dashboard'
import ChartController from './controllers/chart'
import QuickstatsController from './controllers/quickstats'
import SubmenuController from './controllers/submenu'

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

Stimulus.register('base', BaseController)
Stimulus.register('dashboard', DashboardController)
Stimulus.register('chart', ChartController)
Stimulus.register('quickstats', QuickstatsController)
Stimulus.register('submenu', SubmenuController)

export { application }
