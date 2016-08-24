# -*- coding: utf-8 -*-
# rubocop:disable GlobalVars, SpecialGlobalVars

# Some reading: http://felipec.wordpress.com/2013/11/04/init/

require 'date'
require 'fileutils'

STDOUT.sync = true

$processes = {}

def log(message)
  puts "[#{DateTime.now}] INIT: #{message}"
end

def run!(*args, &block)
  log "Starting: #{args}" if ENV['DEBUG']
  pid = Process.spawn(*args)
  log "Started #{pid}: #{args.join ' '}"
  $processes[pid] = block || -> { log "#{args.join ' '}: #{$?}" }
  pid
end

def reconfigure!(reason = nil)
  if $reconf_pid
    if reason
      log "#{reason}, but cannot reconfigure: already running"
    else
      log 'Cannot reconfigure: already running'
    end
    return
  end

  if reason
    log "#{reason}, reconfiguring"
  else
    log 'Reconfiguring'
  end

  $reconf_pid = run! '/usr/bin/chef-compliance-ctl', 'reconfigure' do
    log "Reconfiguration finished: #{$?}"
    run! 'touch /var/opt/chef-compliance/bootstrapped'
    $reconf_pid = nil
  end
end

def shutdown!
  unless $runsvdir_pid
    log 'ERROR: no runsvdir pid at exit'
    exit 1
  end

  if $reconf_pid
    log "Reconfigure running as #{$reconf_pid}, stopping..."
    Process.kill 'TERM', $reconf_pid
    (1..5).each do
      if $reconf_pid
        sleep 1
      else
        break
      end
    end
    Process.kill 'KILL', $reconf_pid if $reconf_pid
  end

  run! '/usr/bin/chef-compliance-ctl', 'stop' do
    log 'chef-compliance-ctl stop finished, stopping runsvdir'
    Process.kill('HUP', $runsvdir_pid)
  end
end

log "Starting #{$PROGRAM_NAME}"

{ shmmax: 17_179_869_184, shmall: 4_194_304 }.each do |param, value|
  next unless (actual = File.read("/proc/sys/kernel/#{param}").to_i) < value
  log "kernel.#{param} = #{actual}, setting to #{value}."
  begin
    File.write "/proc/sys/kernel/#{param}", value.to_s
  rescue
    log "Cannot set kernel.#{param} to #{value}: #{$!}"
    log 'You may need to run the container in privileged mode or set sysctl on host.'
    raise
  end
end

log 'Preparing configuration ...'
FileUtils.mkdir_p %w(/var/opt/chef-compliance/log /var/opt/chef-compliance/etc), verbose: true
FileUtils.cp '/.chef/chef-compliance.rb', '/var/opt/chef-compliance/etc', verbose: true

$runsvdir_pid = run! '/opt/chef-compliance/embedded/bin/runsvdir-start' do
  log "runsvdir exited: #{$?}"
  if $?.success? || $?.exitstatus == 111
    exit
  else
    exit $?.exitstatus
  end
end

Signal.trap 'TERM' do
  shutdown!
end

Signal.trap 'INT' do
  shutdown!
end

Signal.trap 'HUP' do
  reconfigure! 'Got SIGHUP'
end

Signal.trap 'USR1' do
  log 'Chef Server status:'
  run! '/usr/bin/chef-compliance-ctl', 'status'
end

# Chef Compliance does not create this bootstrapped file and we can
# only guess if the initial reconfigure worked.
unless File.exist? '/var/opt/chef-compliance/bootstrapped'
  reconfigure! 'Not bootstrapped'
end

loop do
  log $? if ENV['DEBUG']
  handler = $processes.delete(Process.wait)
  handler.call if handler
end
