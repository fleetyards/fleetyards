export const routes = [
  {
    component: () => import('@/frontend/pages/Tools/TradeRoutes/index.vue'),
    meta: {
      backgroundImage: 'bg-7',
      title: 'tools.tradeRoutes',
    },
    name: 'trade-routes',
    path: 'trade-routes/',
  },
  {
    component: () =>
      import('@/frontend/pages/Tools/ProfitCalculator/index.vue'),
    meta: {
      backgroundImage: 'bg-8',
      title: 'tools.profitCalculator',
    },
    name: 'profit-calculator',
    path: 'profit-calculator/',
  },
]

export default routes
