json.unlisted_models_count @dashboard[:unlisted_models_count] if @dashboard.key?(:unlisted_models_count)
json.catalogue_version @dashboard[:catalogue_version] if @dashboard.key?(:catalogue_version)
json.catalogue_loaded_at @dashboard[:catalogue_loaded_at] if @dashboard.key?(:catalogue_loaded_at)

json.failed_imports_count @dashboard[:failed_imports_count] if @dashboard.key?(:failed_imports_count)
json.stuck_imports_count @dashboard[:stuck_imports_count] if @dashboard.key?(:stuck_imports_count)

json.unresolved_rsi_request_logs_count @dashboard[:unresolved_rsi_request_logs_count] if @dashboard.key?(:unresolved_rsi_request_logs_count)

json.actionable_notifications_count @dashboard[:actionable_notifications_count] if @dashboard.key?(:actionable_notifications_count)

json.jobs_enqueued_count @dashboard[:jobs_enqueued_count] if @dashboard.key?(:jobs_enqueued_count)
json.jobs_retry_count @dashboard[:jobs_retry_count] if @dashboard.key?(:jobs_retry_count)
json.jobs_dead_count @dashboard[:jobs_dead_count] if @dashboard.key?(:jobs_dead_count)

json.online_count @dashboard[:online_count] if @dashboard.key?(:online_count)
json.visits_today @dashboard[:visits_today] if @dashboard.key?(:visits_today)
json.visits_same_weekday_last_week @dashboard[:visits_same_weekday_last_week] if @dashboard.key?(:visits_same_weekday_last_week)
json.signups_this_week @dashboard[:signups_this_week] if @dashboard.key?(:signups_this_week)
json.signups_last_week @dashboard[:signups_last_week] if @dashboard.key?(:signups_last_week)
