# These querries use the VS Code extension REST Client
# Useful for polling REST interfaces to check 
#  '###' separates the querries.  Place your cursor in the section with the 
# querry you want to run and select send request from the command pallet.

###
#  To retrieve event status counts for each node:

POST https://master.vm:8081/pdb/query/v4/events
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":["extract", [["function", "count"], "status","certname"],
      ["group_by","status","certname"]]
}

###
#  Find execs with changes that aren't corrective.

POST https://master.vm:8081/pdb/query/v4/events
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":["extract", 
    ["resource_title","status","certname","report_receive_time","corrective_change"],
      ["and", 
        ["=", "resource_type", "Exec"],
        ["=", "status", "noop"],
        ["=", "corrective_change", false]
      ]
    ]
}

###
#  Find most recent exec which was not corrective
#  Last instance of intentional, noop.
#  Use this one.

POST https://master.vm:8081/pdb/query/v4
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":["from", "events", 
      ["and", 
        ["=", "certname", "linux.vm"],
        ["=", "resource_type", "Exec"],
        ["=", "resource_title", "Test adding a file with content"],
        ["=", "status", "noop"],
        ["~", "message", "notrun"],
        ["=", "corrective_change", false]
      ],
      ["order_by", [["report_receive_time", "desc"]]],
      ["limit", 1]
    ]
}

###
#  Look for Exec run successfully newer than last
#  intentional action.
#  Use this one.

POST https://master.vm:8081/pdb/query/v4
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":["from", "events", 
      ["and", 
        ["=", "certname", "linux.vm"],
        ["=", "resource_type", "Exec"],
        ["=", "resource_title", "Test adding a file with content"],
        ["=", "status", "success"],
        [">", "run_end_time", "2019-03-15T17:04:03.321Z"]
      ],
      ["order_by", [["report_receive_time", "desc"]]],
      ["limit", 1]
    ]
}


###
#  Find most recent exec which was not corrective
#  Test query

POST https://master.vm:8081/pdb/query/v4
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":["from", "events", 
      ["and", 
        ["=", "certname", "linux.vm"],
        ["=", "resource_type", "Exec"]
      ],
      ["order_by", [["report_receive_time", "desc"]]],
      ["limit", 5]
    ]
}

###
#  Find execs in the most recent events

POST https://master.vm:8081/pdb/query/v4
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":["from", "events", 
      ["=", "resource_type", "Exec"],
      ["order_by", [["report_receive_time", "desc"]]],
      ["limit", 1]
    ]
}

###
#  Find corrective changes in the reports

POST https://master.vm:8081/pdb/query/v4
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":["from", "reports",
      ["and",
      ["=", "latest_report?", true],
      ["=", "noop_pending", true],
      ["=", "corrective_change", true]
      ]
    ]
}

###
#  Find report which does not contain the specified 
#  Exec event.

POST https://master.vm:8081/pdb/query/v4/reports
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":["extract", [["function", "count"], "certname"],
        ["=", "certname", "linux.vm"],
        ["group_by", "certname"]
  ]
}

###
#  Find report which does not contain the specified 
#  Exec event. Just count the number of reports.

POST https://master.vm:8081/pdb/query/v4/reports
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":
      ["extract", [["function", "count"], "certname"],
      ["and",
        ["=", "certname", "linux.vm"],
        ["subquery", "events",
          ["not",
            ["=", "resource_title", "Test adding a file with content"]
          ]
        ]
      ],
      ["group_by", "certname"]
    ]
}

###
#  Find report which does not contain the specified 
#  Exec event. Just count the number of reports.

POST https://master.vm:8081/pdb/query/v4/reports
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":
      ["extract", "receive_time",
      ["and",
        ["=", "certname", "linux.vm"],
        ["subquery", "events",
          ["not",
            ["=", "resource_title", "Test adding a file with content"]
          ]
        ]
      ],
    ["order_by", [["receive_time", "desc"]]],
    ["limit", 3]
    ]
}

###
#  Find report which does not contain the specified 
#  Exec event and is newer than the timestamp
#  of the last intentional exec.

POST https://master.vm:8081/pdb/query/v4/reports
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":
      ["extract", "end_time",
      ["and",
        ["=", "certname", "linux.vm"],
        [">", "end_time", "2019-03-15T17:04:03.321Z"],
        ["subquery", "events",
          ["not",
            ["~", "resource_title", "Test adding a file with content"]
          ]
        ]
      ]
    ]
}


###
#  Find corrective changes in the reports 
# We can't filter on old value with this query.

POST https://master.vm:8081/pdb/query/v4/reports
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":["extract", ["certname", "resource_events"],
      ["and",
      ["=", "latest_report?", true],
      ["=", "noop_pending", true],
      ["=", "corrective_change", true]
      ]
    ]
}

###
#  Find corrective changes in the events 

POST https://master.vm:8081/pdb/query/v4/events
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":
    ["extract", ["certname", "resource_type", "resource_title"],
      ["and",
        ["=", "latest_report?", true],
        ["=", "corrective_change", true],
        ["not", ["=", "old_value", "notrun"]]
      ]
    ]
}

###
["extract", [["function", "avg", "value"]], ["=", "name", "uptime_seconds"]]

###
#  Find corrective changes in the events 

POST https://master.vm:8081/pdb/query/v4/events
X-Authentication: 0KIxHTEmIc1xtTLU_h5iT-oLabaZQf6wwcfC_AA0p5YE

{
  "query":
        ["=", "latest_report?", true]
}
#{
#  "query":
#      ["and",
#        ["=", "latest_report?", true],
#        ["=", "corrective_change", true]
#      ]
#}
