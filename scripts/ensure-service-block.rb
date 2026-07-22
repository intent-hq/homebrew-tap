#!/usr/bin/env ruby
# frozen_string_literal: true

# Idempotently (re-)inserts the `service do ... end` block into
# Formula/intentd.rb.
#
# The formula is regenerated wholesale by intentd's release CI (cargo-dist,
# `publish-jobs = ["homebrew"]`), which overwrites any hand-maintained edits.
# This script restores the service block after regeneration; running it when
# the block is already present is a no-op.
#
# Usage: ruby scripts/ensure-service-block.rb [path-to-formula]

FORMULA = ARGV.fetch(0, File.expand_path("../Formula/intentd.rb", __dir__))

# Mirrors intentd's own LaunchAgent plist (intentd/src/service.rs):
# ProgramArguments = [intentd, serve, --listen, uds]; KeepAlive relaunches on
# crash but not on clean exit, so `brew services stop intentd` sticks.
SERVICE_BLOCK = <<~RUBY
  # `brew services start intentd` runs the daemon under launchd/systemd:
  # it starts now and at every user login (boot-level start is out of scope).
  # KeepAlive mirrors intentd's own LaunchAgent plist: relaunch on crash,
  # but a clean exit (`brew services stop intentd`) does not relaunch.
  # The Intent desktop app auto-detects and connects to the brew-managed
  # daemon on the default UDS socket.
  service do
    run [opt_bin/"intentd", "serve", "--listen", "uds"]
    keep_alive crashed: true, successful_exit: false
    log_path var/"log/intentd.log"
    error_log_path var/"log/intentd.err.log"
  end
RUBY

content = File.read(FORMULA)

if content.match?(/^\s*service do\s*$/)
  puts "service block already present in #{FORMULA} -- nothing to do"
  exit 0
end

lines = content.lines
closing = lines.rindex { |line| line.strip == "end" }
abort "could not locate the closing `end` of the formula class" if closing.nil?

block = SERVICE_BLOCK.lines.map { |l| l.strip.empty? ? "\n" : "  #{l}" }
lines.insert(closing, "\n", *block)
File.write(FORMULA, lines.join)
puts "inserted service block into #{FORMULA}"
