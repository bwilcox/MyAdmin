#!/usr/bin/ruby
# This script is an example of how to determine if an exec was listed as
# intentional durring a specified timeframe.
#
# Attempting to solve the problem where the first time an exec is run 
# in a noop configured environment it shows up as intentional.  Every time 
# after that it shows up as corrective, even when the exec has not yet
# been run in enforcement mode.
#

require 'rest-client'
require 'json'

$URL = 'https://master.vm:8081/pdb/query/v4'
$token = '0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE'
$offset = 8

# Find all execs with corrective changes from the most 
# recent reports between current time and (current time - offset)

most_recent = {
    "query" => ["from", "events", 
        ["and", 
          ["=", "status", "noop"],
          ["=", "corrective_change", true],
          ["=", "latest_report?", true]
        ]
      ]
  }

#puts query.to_json

corrective_changes = RestClient::Request.execute(method: :post, url: $URL, 
    headers: {'X-Authentication': $token, 'Content-Type': 'application/json'},
    verify_ssl: false, payload: most_recent.to_json) 

output = JSON.parse(corrective_changes.body)

puts JSON.pretty_generate(output)

# Go back in time for each exec and see what the change was
# before if became corrective.

first_instance = {
    "query" => ["from", "events", 
        ["and", 
          ["=", "resource_type", "Exec"],
          ["=", "resource_title", "Test adding a file with content"],
          ["=", "status", "noop"],
          ["=", "corrective_change", false]
        ],
        ["order_by", [["report_receive_time", "desc"]]],
        ["limit", 1]
      ]
  }

first_change = RestClient::Request.execute(method: :post, url: $URL, 
    headers: {'X-Authentication': $token, 'Content-Type': 'application/json'},
    verify_ssl: false, payload: first_instance.to_json) 

output2 = JSON.parse(first_change.body)

puts 'First instance of the exec that was not a corrective change'
puts JSON.pretty_generate(output2)

# If the status before corrective is intentional, then the
# change is still intentional.