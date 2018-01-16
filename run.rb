#!/usr/bin/env ruby
require_relative 'lib/notifier'
require_relative 'environment'

ignore_fill_seconds = 60 * 60 * 24
poller = Notifier.new(ignore_fill_seconds)
poller.poll
