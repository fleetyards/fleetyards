import { Application } from '@hotwired/stimulus'
import BaseController from './controllers/base'
import DashboardController from './controllers/dashboard'
import ChartController from './controllers/chart'
import QuickstatsController from './controllers/quickstats'
import SubmenuController from './controllers/submenu'

const application = Application.start()

// Configure Stimulus development experience
application.stimulusUseDebug = true

application.register('base', BaseController)
application.register('dashboard', DashboardController)
application.register('chart', ChartController)
application.register('quickstats', QuickstatsController)
application.register('submenu', SubmenuController)

window.Stimulus = application

export { application }
