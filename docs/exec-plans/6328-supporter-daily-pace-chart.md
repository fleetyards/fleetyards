# Daily pace chart for supporter contributions

Working plan for #6328. Decisions live in the issue body. Deleted before the PR merges.

## Goal
The admin supporter contributions page shows a cumulative per-day line chart for the current month and the three before it.

## What changed

### Phase 1 — Backend
1. `SupporterDailyStats` in `app/lib/`, loading like `SupporterMonthlyStats`
2. `GET /supporter-contributions/per-day` with `SupporterContributionDailyStats` components
3. Unit + integration tests

### Phase 2 — Frontend
1. `SupporterContributions/DailyChart` Highcharts line chart
2. Panel on the supporter contributions page, locales in all 7 languages
3. Spec + e2e assertion

## Key files

| File | Role |
|------|------|
| `app/lib/supporter_daily_stats.rb` | Day buckets |
| `app/controllers/admin/api/v1/supporter_contributions_controller.rb` | `per_day` action |
| `app/frontend/admin/components/SupporterContributions/DailyChart/index.vue` | Chart |

## Discovery Log

- **2026-11-14** Initial research and plan creation

## Progress
- [ ] Phase 1
- [ ] Phase 2
