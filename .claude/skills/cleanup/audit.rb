#!/usr/bin/env ruby
# frozen_string_literal: true

# Audits the local development state — worktrees, branches, Postgres databases
# and Redis database bands — and reports which of them nothing is using any more.
# Read-only unless --apply is passed.

require "json"
require "open3"
require "optparse"
require "uri"

CATEGORIES = %w[worktrees dirs branches databases redis].freeze

OPTIONS = {json: false, apply: false, only: CATEGORIES, github: true, sizes: true}

OptionParser.new do |opts|
  opts.banner = "Usage: audit.rb [options]"
  opts.on("--json", "Emit the report as JSON instead of text") { OPTIONS[:json] = true }
  opts.on("--apply", "Remove what is classified as removable") { OPTIONS[:apply] = true }
  opts.on("--only=LIST", "Restrict to #{CATEGORIES.join(",")}") do |value|
    selected = value.split(",").map(&:strip)
    unknown = selected - CATEGORIES
    abort("Unknown category: #{unknown.join(", ")}") if unknown.any?
    OPTIONS[:only] = selected
  end
  opts.on("--no-github", "Skip the pull-request lookup") { OPTIONS[:github] = false }
  opts.on("--no-sizes", "Skip disk and database size measurement") { OPTIONS[:sizes] = false }
end.parse!

def enabled?(category) = OPTIONS[:only].include?(category)

def sh(*cmd)
  out, err, status = Open3.capture3(*cmd)
  [out, err, status.success?]
end

def capture(*cmd)
  out, _err, ok = sh(*cmd)
  ok ? out : ""
end

def tool?(name) = !capture("command", "-v", name).empty? || File.exist?("/usr/bin/#{name}")

# `--path-format=absolute` matters: from the main checkout the plain form
# answers a relative `.git`, which resolves against the caller's directory
# rather than the repository's.
GIT_COMMON = capture("git", "rev-parse", "--path-format=absolute", "--git-common-dir").strip
abort("Not inside a git repository.") if GIT_COMMON.empty?
MAIN_ROOT = File.dirname(GIT_COMMON)
WORKTREE_PARENT = File.join(MAIN_ROOT, ".worktrees")

# Mirrors bin/setup. A worktree owns one slot; the slot owns a band of Redis
# databases, and config/redis.yml maps each subsystem to an offset inside it.
# The main checkout leaves REDIS_DB unset and takes the first band.
REDIS_DBS_PER_CHECKOUT = 4
REDIS_DB_BASE = REDIS_DBS_PER_CHECKOUT

# Branches whose only copy of the work is local, held on purpose. Never offered.
PROTECTED_BRANCHES = [%r{\Amain\z}, %r{\Aparked/}].freeze
# Held deliberately but disposable once the user says so.
ASK_ONLY_BRANCHES = [%r{\Abackup/}].freeze

DB_HOST = ENV["DB_HOST"] || "localhost"
DB_USER = ENV["DB_USER"] || "root"
DB_PASSWORD = ENV["DB_PASSWORD"] || "password"

def env_value(path, key)
  return nil unless File.exist?(path)

  File.read(path)[/^#{Regexp.escape(key)}=(.*)$/, 1]&.strip
end

def db_port
  ENV["DB_PORT"] ||
    env_value(File.join(MAIN_ROOT, ".env.local"), "DB_PORT") ||
    env_value(File.join(MAIN_ROOT, ".env"), "DB_PORT") ||
    "8271"
end

def redis_url
  ENV["REDIS_URL"] ||
    env_value(File.join(MAIN_ROOT, ".env.local"), "REDIS_URL") ||
    env_value(File.join(MAIN_ROOT, ".env"), "REDIS_URL") ||
    "redis://localhost:8272"
end

# The statements go in over stdin rather than through `-c`: psql wraps several
# `-c` statements in one implicit transaction, and DROP DATABASE refuses to run
# inside a transaction block.
def psql(sql)
  out, err, status = Open3.capture3(
    {"PGPASSWORD" => DB_PASSWORD},
    "psql", "-h", DB_HOST, "-p", db_port, "-U", DB_USER, "-d", "postgres",
    "-X", "-A", "-t", "-F", "\t", "-v", "ON_ERROR_STOP=1", "-f", "-",
    stdin_data: sql
  )
  [out, err, status.success?]
end

def redis_cli(*args)
  uri = URI(redis_url)
  capture("redis-cli", "-h", uri.host || "localhost", "-p", (uri.port || 6379).to_s, *args)
end

def human_bytes(bytes)
  return "-" if bytes.nil?

  units = %w[B KB MB GB TB]
  value = bytes.to_f
  unit = 0
  while value >= 1024 && unit < units.length - 1
    value /= 1024
    unit += 1
  end
  format(value >= 100 || unit.zero? ? "%.0f %s" : "%.1f %s", value, units[unit])
end

# --- discovery ---------------------------------------------------------------

# bin/setup's sanitize_worktree_name: the 20-character cut is why a database
# name cannot be mapped back to a worktree by reading it — two long names can
# truncate to the same suffix. Suffixes are always derived forwards, from the
# worktrees that exist, and everything outside that set is what gets swept.
def sanitize_worktree_name(name) = name.gsub(/[^a-zA-Z0-9]/, "_")[0, 20]

def supacode_worktrees
  return [] unless tool?("supacode")

  capture("supacode", "worktree", "list").lines.filter_map do |line|
    decoded = URI.decode_www_form_component(line.strip)
    next if decoded.empty?

    decoded.chomp("/")
  end
end

def worktrees
  supacode = supacode_worktrees
  entries = []
  current = nil

  capture("git", "-C", MAIN_ROOT, "worktree", "list", "--porcelain").each_line do |raw|
    line = raw.chomp
    case line
    when /\Aworktree (.+)\z/
      current = {path: $1, locked: false, detached: false, branch: nil}
      entries << current
    when /\AHEAD (.+)\z/ then current[:head] = $1
    when %r{\Abranch refs/heads/(.+)\z} then current[:branch] = $1
    when "detached" then current[:detached] = true
    when /\Alocked/ then current[:locked] = true
    end
  end

  entries.each do |entry|
    path = entry[:path]
    entry[:main] = File.identical?(path, MAIN_ROOT)
    entry[:supacode] = supacode.include?(path.chomp("/"))
    entry[:dirty] = capture("git", "-C", path, "status", "--porcelain").lines.size
    entry[:suffix] =
      if entry[:main]
        ""
      else
        env_value(File.join(path, ".env.local"), "WORKTREE_SUFFIX") ||
          env_value(File.join(path, ".env.test.local"), "WORKTREE_SUFFIX") ||
          "_wt_#{sanitize_worktree_name(File.basename(path))}"
      end
    entry[:slot] = entry[:main] ? nil : env_value(File.join(path, ".env.local"), "WORKTREE_SLOT")&.to_i
    entry[:setup] = !entry[:main] && File.exist?(File.join(path, ".env.local"))
    entry[:size] = OPTIONS[:sizes] && !entry[:main] ? capture("du", "-sk", path).split("\t").first.to_i * 1024 : nil
  end
end

def orphan_dirs(worktree_paths)
  return [] unless Dir.exist?(WORKTREE_PARENT)

  registered = worktree_paths.map { |path| File.expand_path(path) }
  Dir.glob(File.join(WORKTREE_PARENT, "*")).select { |path| File.directory?(path) }.filter_map do |path|
    absolute = File.expand_path(path)
    next if registered.any? { |known| known == absolute || known.start_with?("#{absolute}/") }

    {
      path: absolute,
      size: OPTIONS[:sizes] ? capture("du", "-sk", absolute).split("\t").first.to_i * 1024 : nil,
      dirty: Dir.exist?(File.join(absolute, ".git")) || File.exist?(File.join(absolute, ".git"))
    }
  end
end

def repo_slug
  capture("git", "-C", MAIN_ROOT, "remote", "get-url", "origin").strip[%r{[:/]([^/:]+/[^/]+?)(?:\.git)?\z}, 1]
end

# Squash merges are the rule here, so a merged branch is never an ancestor of
# main and `git branch --merged` cannot see it. The pull request's state is the
# only reliable evidence that the work landed.
def pull_requests
  return @pull_requests if defined?(@pull_requests)

  @pull_requests = fetch_pull_requests
end

def fetch_pull_requests
  return {} unless OPTIONS[:github]

  slug = repo_slug
  return {} unless slug

  out, _err, ok = sh("gh", "pr", "list", "--repo", slug, "--state", "all",
    "--limit", "600", "--json", "headRefName,state,number,title")
  return {} unless ok

  JSON.parse(out).group_by { |pr| pr["headRefName"] }
rescue JSON::ParserError
  {}
end

def branches(worktree_list)
  prs = pull_requests
  checked_out = worktree_list.to_h { |entry| [entry[:branch], entry[:path]] }
  format = "%(refname:short)\t%(upstream)\t%(upstream:track)\t%(committerdate:short)\t%(objectname:short)"

  capture("git", "-C", MAIN_ROOT, "for-each-ref", "--format=#{format}", "refs/heads").lines.map do |line|
    name, upstream, track, date, sha = line.chomp.split("\t", 5)
    entry = {
      name: name, upstream: upstream.to_s, gone: track.to_s.include?("gone"),
      date: date, sha: sha, worktree: checked_out[name],
      prs: (prs[name] || []).map { |pr| {number: pr["number"], state: pr["state"]} }
    }
    entry[:merged] = entry[:prs].any? { |pr| pr[:state] == "MERGED" }
    entry[:open] = entry[:prs].any? { |pr| pr[:state] == "OPEN" }
    entry[:ahead] = capture("git", "-C", MAIN_ROOT, "rev-list", "--count", "origin/main..#{name}").strip.to_i
    classify_branch(entry)
  end
end

def classify_branch(entry)
  name = entry[:name]
  entry[:verdict], entry[:reason] =
    if entry[:worktree]
      [:keep, "checked out in #{entry[:worktree].sub("#{MAIN_ROOT}/", "")}"]
    elsif PROTECTED_BRANCHES.any? { |pattern| name.match?(pattern) }
      [:keep, "protected namespace"]
    elsif entry[:open]
      [:keep, "pull request ##{entry[:prs].find { |pr| pr[:state] == "OPEN" }[:number]} still open"]
    elsif ASK_ONLY_BRANCHES.any? { |pattern| name.match?(pattern) }
      [:ask, "kept on purpose — #{entry[:ahead]} commit(s) not on origin/main"]
    elsif entry[:merged]
      [:remove, "pull request ##{entry[:prs].find { |pr| pr[:state] == "MERGED" }[:number]} merged"]
    elsif entry[:ahead].zero?
      [:remove, "no commits of its own beyond origin/main"]
    elsif !entry[:upstream].empty? && !entry[:gone]
      [:keep, "upstream branch still exists"]
    elsif entry[:prs].any?
      [:ask, "pull request ##{entry[:prs].first[:number]} closed unmerged — #{entry[:ahead]} commit(s) would be lost"]
    else
      [:ask, "never opened as a pull request — #{entry[:ahead]} commit(s) would be lost"]
    end
  entry
end

def databases(worktree_list)
  out, err, ok = psql(<<~SQL)
    select datname, pg_database_size(datname)
    from pg_database
    where datname like 'fleetyards%' and not datistemplate
    order by datname
  SQL
  return [{error: err.strip}] unless ok

  keep = keep_database_patterns(worktree_list)

  out.lines.filter_map do |line|
    name, size = line.chomp.split("\t")
    next if name.to_s.empty?

    owner = keep.find { |_, pattern| name.match?(pattern) }
    entry = {name: name, size: size.to_i}
    entry[:verdict], entry[:reason] =
      if owner
        [:keep, owner.first]
      elsif name.start_with?("fleetyards_dev_", "fleetyards_test_")
        [:remove, "no worktree claims this suffix"]
      else
        [:keep, "not a worktree database — left alone"]
      end
    entry
  end
end

# One pattern per checkout, built from the worktrees that exist right now. The
# main checkout leaves WORKTREE_SUFFIX unset, so its own databases are the bare
# names. TEST_ENV_NUMBER appends `_N` for each parallel test worker.
def keep_database_patterns(worktree_list)
  worktree_list.map do |entry|
    suffix = Regexp.escape(entry[:suffix].to_s)
    label = entry[:main] ? "main checkout" : File.basename(entry[:path])
    [label, /\Afleetyards_(dev|test)#{suffix}(_\d+)?\z/]
  end
end

def redis_bands(worktree_list)
  keyspace = redis_cli("info", "keyspace")
  return [{error: "redis unreachable at #{redis_url}"}] if keyspace.empty?

  keep = {}
  (0...REDIS_DB_BASE).each { |index| keep[index] = "main checkout" }
  worktree_list.each do |entry|
    next if entry[:main] || entry[:slot].nil?

    base = REDIS_DB_BASE + (entry[:slot] * REDIS_DBS_PER_CHECKOUT)
    (base...(base + REDIS_DBS_PER_CHECKOUT)).each { |index| keep[index] = File.basename(entry[:path]) }
  end

  keyspace.scan(/^db(\d+):keys=(\d+)/).map do |index, keys|
    index = index.to_i
    entry = {index: index, keys: keys.to_i}
    entry[:verdict], entry[:reason] =
      if keep.key?(index)
        [:keep, keep[index]]
      else
        [:remove, "slot #{(index - REDIS_DB_BASE) / REDIS_DBS_PER_CHECKOUT} is held by no worktree"]
      end
    entry
  end
end

# --- report ------------------------------------------------------------------

def section(title, rows, empty_note)
  puts
  puts title
  puts "-" * title.length
  if rows.empty?
    puts "  #{empty_note}"
    return
  end
  rows.each { |line| puts "  #{line}" }
end

def marker(verdict) = {remove: "DROP", ask: "ASK ", keep: "keep"}.fetch(verdict)

def text_report(report)
  puts "Local state audit — #{MAIN_ROOT}"

  if enabled?("worktrees")
    rows = report[:worktrees].reject { |entry| entry[:main] }.map do |entry|
      details = [
        entry[:branch] || "detached #{entry[:head]&.slice(0, 9)}",
        entry[:dirty].zero? ? "clean" : "#{entry[:dirty]} uncommitted file(s)",
        entry[:setup] ? "slot #{entry[:slot]}" : "never set up",
        entry[:supacode] ? "supacode" : "git only",
        human_bytes(entry[:size])
      ]
      "#{marker(entry[:verdict])}  #{File.basename(entry[:path]).ljust(32)} #{details.join(" · ")}\n        #{entry[:reason]}"
    end
    section("Worktrees", rows, "no worktrees besides the main checkout")
  end

  if enabled?("dirs")
    rows = report[:dirs].map do |entry|
      "#{marker(entry[:verdict])}  #{File.basename(entry[:path]).ljust(32)} #{human_bytes(entry[:size])} · #{entry[:reason]}"
    end
    section("Leftover directories under .worktrees/", rows, "none")
  end

  if enabled?("branches")
    grouped = report[:branches].group_by { |entry| entry[:verdict] }
    rows = (grouped[:remove] || []).map { |entry| "#{marker(:remove)}  #{entry[:name].ljust(46)} #{entry[:reason]}" }
    rows += (grouped[:ask] || []).map { |entry| "#{marker(:ask)}  #{entry[:name].ljust(46)} #{entry[:reason]}" }
    rows << "keep  #{(grouped[:keep] || []).length} branch(es) in active use or protected"
    section("Local branches (#{report[:branches].length} total)", rows, "none")
  end

  if enabled?("databases")
    error = report[:databases].find { |entry| entry[:error] }
    if error
      section("Postgres databases", ["unreachable: #{error[:error]}"], "none")
    else
      grouped = report[:databases].group_by { |entry| entry[:verdict] }
      removable = grouped[:remove] || []
      rows = removable.group_by { |entry| entry[:name].sub(/_\d+\z/, "") }.map do |base, family|
        size = family.sum { |entry| entry[:size] }
        "#{marker(:remove)}  #{base.ljust(46)} #{family.length} database(s) · #{human_bytes(size)}"
      end
      kept = (grouped[:keep] || []).group_by { |entry| entry[:reason] }
      rows += kept.map { |reason, family| "keep  #{reason.ljust(46)} #{family.length} database(s) · #{human_bytes(family.sum { |e| e[:size] })}" }
      section("Postgres databases (#{report[:databases].length} total)", rows, "none")
    end
  end

  if enabled?("redis")
    error = report[:redis].find { |entry| entry[:error] }
    rows =
      if error
        ["unreachable: #{error[:error]}"]
      else
        report[:redis].map { |entry| "#{marker(entry[:verdict])}  db#{entry[:index].to_s.ljust(44)} #{entry[:keys]} key(s) · #{entry[:reason]}" }
      end
    section("Redis databases in use", rows, "none")
  end

  puts
  puts "Reclaimable"
  puts "-----------"
  totals = report[:totals]
  puts "  worktrees:  #{totals[:worktrees]} · #{human_bytes(totals[:worktree_bytes])}" if enabled?("worktrees")
  puts "  leftovers:  #{totals[:dirs]} · #{human_bytes(totals[:dir_bytes])}" if enabled?("dirs")
  puts "  branches:   #{totals[:branches]} removable, #{totals[:branches_ask]} need a decision" if enabled?("branches")
  puts "  databases:  #{totals[:databases]} · #{human_bytes(totals[:database_bytes])}" if enabled?("databases")
  puts "  redis:      #{totals[:redis]} database(s) to flush" if enabled?("redis")
  puts "  (categories not selected are not scanned and not counted)" if OPTIONS[:only] != CATEGORIES
  puts
  puts "Read-only. Re-run with --apply to remove, and again afterwards:"
  puts "removing a worktree orphans its databases and Redis band, which this"
  puts "run still counts as in use."
end

# --- apply -------------------------------------------------------------------

def apply_worktrees(rows)
  rows.each do |entry|
    path = entry[:path]
    if entry[:supacode]
      _out, err, ok = sh("supacode", "worktree", "delete", "--worktree", path, "--background")
      puts(ok ? "  removed #{path} (supacode)" : "  FAILED #{path}: #{err.strip}")
      next
    end
    sh("git", "-C", MAIN_ROOT, "worktree", "unlock", path) if entry[:locked]
    _out, err, ok = sh("git", "-C", MAIN_ROOT, "worktree", "remove", path)
    puts(ok ? "  removed #{path}" : "  FAILED #{path}: #{err.strip}")
  end
  sh("git", "-C", MAIN_ROOT, "worktree", "prune") if rows.any?
end

def apply_dirs(rows)
  rows.each do |entry|
    path = entry[:path]
    # A path outside .worktrees/ can only be a bug in discovery; refuse it
    # rather than hand rm -rf an unexpected argument.
    unless File.expand_path(path).start_with?("#{WORKTREE_PARENT}/")
      puts "  REFUSED #{path}: outside #{WORKTREE_PARENT}"
      next
    end
    _out, err, ok = sh("rm", "-rf", path)
    puts(ok ? "  removed #{path}" : "  FAILED #{path}: #{err.strip}")
  end
end

def apply_branches(rows)
  rows.each_slice(40) do |slice|
    _out, err, ok = sh("git", "-C", MAIN_ROOT, "branch", "-D", *slice.map { |entry| entry[:name] })
    puts(ok ? "  deleted #{slice.length} branch(es)" : "  FAILED: #{err.strip}")
  end
end

def apply_databases(rows)
  # FORCE (Postgres 13+) terminates the leftover connections a crashed test run
  # leaves behind, which otherwise fail the drop with PG::ObjectInUse.
  rows.each_slice(50) do |slice|
    sql = slice.map { |entry| %(DROP DATABASE IF EXISTS "#{entry[:name]}" WITH (FORCE);) }.join("\n")
    _out, err, ok = psql(sql)
    puts(ok ? "  dropped #{slice.length} database(s)" : "  FAILED: #{err.strip}")
  end
end

def apply_redis(rows)
  rows.each do |entry|
    redis_cli("-n", entry[:index].to_s, "flushdb")
    puts "  flushed db#{entry[:index]}"
  end
end

# --- main --------------------------------------------------------------------

worktree_list = worktrees
worktree_list.each do |entry|
  entry[:verdict], entry[:reason] =
    if entry[:main]
      [:keep, "main checkout"]
    elsif entry[:dirty].positive?
      [:keep, "#{entry[:dirty]} uncommitted file(s) — commit or discard them first"]
    else
      branch = entry[:branch]
      prs = branch ? pull_requests[branch] : nil
      merged = prs&.find { |pr| pr["state"] == "MERGED" }
      open_pr = prs&.find { |pr| pr["state"] == "OPEN" }
      ahead = branch ? capture("git", "-C", MAIN_ROOT, "rev-list", "--count", "origin/main..#{branch}").strip.to_i : 0
      if open_pr
        [:keep, "pull request ##{open_pr["number"]} still open"]
      elsif merged
        [:remove, "clean, pull request ##{merged["number"]} merged"]
      elsif ahead.zero?
        # A worktree prepared for work that has not started yet is
        # indistinguishable from one whose work is finished, so this never
        # decides on its own.
        [:ask, "clean and level with origin/main — either finished or not started yet"]
      else
        [:ask, "clean, but #{ahead} commit(s) are not on origin/main and no pull request merged them"]
      end
    end
end

report = {
  worktrees: enabled?("worktrees") ? worktree_list : [],
  dirs: enabled?("dirs") ? orphan_dirs(worktree_list.map { |entry| entry[:path] }).each { |entry| entry[:verdict], entry[:reason] = [:remove, entry[:dirty] ? "not a registered worktree — left behind by a removal" : "empty leftover"] } : [],
  branches: enabled?("branches") ? branches(worktree_list) : [],
  databases: enabled?("databases") ? databases(worktree_list) : [],
  redis: enabled?("redis") ? redis_bands(worktree_list) : []
}

removable = ->(rows) { rows.select { |entry| entry[:verdict] == :remove } }
report[:totals] = {
  worktrees: removable.call(report[:worktrees].reject { |e| e[:main] }).length,
  worktree_bytes: removable.call(report[:worktrees].reject { |e| e[:main] }).sum { |e| e[:size].to_i },
  dirs: removable.call(report[:dirs]).length,
  dir_bytes: removable.call(report[:dirs]).sum { |e| e[:size].to_i },
  branches: removable.call(report[:branches]).length,
  branches_ask: report[:branches].count { |e| e[:verdict] == :ask },
  databases: removable.call(report[:databases].reject { |e| e[:error] }).length,
  database_bytes: removable.call(report[:databases].reject { |e| e[:error] }).sum { |e| e[:size].to_i },
  redis: removable.call(report[:redis].reject { |e| e[:error] }).length
}

if OPTIONS[:apply]
  puts "Applying to: #{OPTIONS[:only].join(", ")}"
  apply_worktrees(removable.call(report[:worktrees].reject { |e| e[:main] })) if enabled?("worktrees")
  apply_dirs(removable.call(report[:dirs])) if enabled?("dirs")
  apply_branches(removable.call(report[:branches])) if enabled?("branches")
  apply_databases(removable.call(report[:databases].reject { |e| e[:error] })) if enabled?("databases")
  apply_redis(removable.call(report[:redis].reject { |e| e[:error] })) if enabled?("redis")
  puts "Done. Re-run the audit to pick up what these removals orphaned."
elsif OPTIONS[:json]
  puts JSON.pretty_generate(report)
else
  text_report(report)
end
