#!/usr/bin/env ruby193-ruby
#
#  A hook to prevent host creation if naming convention <LOCATION>-<HOSTNAME> is not followed.
#  Created by : Kami Gerami
#  2015-10-09
require 'pp'
require 'json'
require 'yaml'
require 'io/console'

# The logfile path
logfile_path = '/var/log/foreman/hooks'

# and the timestamp of its operation.
rTime = Time.now.getutc

# And the log file, check if that one can be opened.
logfile = File.open(logfile_path, "a")
$stderr = logfile
$stdout = logfile


# What they wana do ('create' or 'destroy')
action = ARGV.shift
# what is the box being created or destroyed?
target = ARGV.shift

if action == 'create'

    # Open STDIN and read the JSON there.
    #
    indata = ARGF.read
    # Parse the data coming from the host ...
    begin 
      hostdata = JSON.parse(indata)

    rescue JSON::ParserError
        puts(indata)
    end

    # There are other stuff which they may put into the hookdata but for us, it's what's inside the 'host' block
    # that we're interrested in.
    hostdata = hostdata['host']
    host_name = target.split('.',2)[0]
    
    if hostdata.has_key?("location_name")
        location = hostdata['location_name']
        if host_name =~/-/
            if location.downcase =~ /#{host_name.split('-',2)[0]}/
              puts sprintf("%s - Success: - %s is named according to naming convention",rTime.to_s, target)
              exit(0)
            end
              prefix_name = host_name.split('-')[0]
              puts sprintf("%s - Failed: - %s NOT named according to naming convention - Prefix wrong : <%s>-  Please prefix <%s>- instead", rTime.to_s, target, prefix_name, location.downcase)
             exit(1)
         else
              puts sprintf("%s - Failed: - %s NOT named according to naming convention - Please prefix hostname with <%s>-<%s>", rTime.to_s, target, location.downcase, host_name)
              exit(1)
        end
    end
end    
