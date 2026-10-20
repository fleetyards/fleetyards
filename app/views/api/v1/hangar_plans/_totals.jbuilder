# frozen_string_literal: true

json.spend_min summary.spend_min.to_f
json.spend_max summary.spend_max.to_f
json.melt_credit summary.melt_credit.to_f
json.starting_credit summary.starting_credit.to_f
json.credit_total summary.credit_total.to_f
json.net_min summary.net_min.to_f
json.net_max summary.net_max.to_f
json.cash_needed_min summary.cash_needed_min.to_f
json.cash_needed_max summary.cash_needed_max.to_f
json.remaining_credit_min summary.remaining_credit_min.to_f
json.remaining_credit_max summary.remaining_credit_max.to_f
json.estimated_melts_count summary.estimated_melts_count
json.open_slots_count summary.count_of("open")
json.decided_slots_count summary.count_of("decided")
json.undecided_slots_count summary.count_of("undecided")
json.unresolved_count summary.unresolved_count
json.complete summary.complete?
