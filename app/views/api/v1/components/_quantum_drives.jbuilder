json.fuel_rate (component.type_data["fuel_rate"] * 1000 * 1000000).round(2) if component.type_data["fuel_rate"].present?
json.jump_range component.type_data["jump_range"] if component.type_data["jump_range"].present?
json.standard_jump do
  json.speed component.type_data["standard_jump"]["Speed"]
  json.cooldown component.type_data["standard_jump"]["Cooldown"]
  json.stage1_acceleration_rate component.type_data["standard_jump"]["Stage1AccelerationRate"]
  json.stage2_acceleration_rate component.type_data["standard_jump"]["State2AccelerationRate"]
  json.spool_up_time component.type_data["standard_jump"]["SpoolUpTime"]
end
json.spline_jump do
  json.speed component.type_data["spline_jump"]["Speed"]
  json.cooldown component.type_data["spline_jump"]["Cooldown"]
  json.stage1_acceleration_rate component.type_data["spline_jump"]["Stage1AccelerationRate"]
  json.stage2_acceleration_rate component.type_data["spline_jump"]["State2AccelerationRate"]
  json.spool_up_time component.type_data["spline_jump"]["SpoolUpTime"]
end
