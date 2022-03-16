export const routes = [
  {
    path: 'trade-routes/',
    name: 'trade-routes',
    component: () => import('@/frontend/pages/Tools/TradeRoutes/index.vue'),
    meta: {
      title: 'tools.tradeRoutes',
      backgroundImage: 'bg-7',
    },
  },
  {
    path: 'profit-calculator/',
    name: 'profit-calculator',
    component: () =>
      import('@/frontend/pages/Tools/ProfitCalculator/index.vue'),
    meta: {
      title: 'tools.profitCalculator',
      backgroundImage: 'bg-8',
    },
  },
]

export default routes
