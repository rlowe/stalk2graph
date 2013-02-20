#!/usr/bin/ruby

require 'rubygems'
require 'getoptlong'
require 'json'

################################################################################
# stalk2graph.rb - Convert pt-stalk output into something easily graphable
#                      (i.e. .csv files readable by R)
#
# - Goal is to keep consistent with:
#   www.percona.com/doc/percona-monitoring-plugins/cacti/mysql-templates.html
# - Assumes pt-stalk version 2.1.2
#
################################################################################

def usage
  puts "stalk2graph.rb --prefix=<PREFIX> [OPTIONS]

--dest:
  Location the output will be stored.
  DEFAULT: `cwd`

-d, --dir:
  Location of pt-stalk output files.
  DEFAULT: /var/lib/pt-stalk

-g, --graph-def:
  Location of the JSON graph definition file
  DEFAULT: graphs.json

-h, --help:
  show help and exit

-p, --prefix:
  pt-stalk date perfix. REQUIRED.
  Example: 2013_02_18_15_25_55

-v, --version:
  display version information and exit
"
  exit
end

opt             = Hash.new
opt[:dest]      = File.expand_path(".")
opt[:dir]       = "/var/lib/pt-stalk/"
opt[:graph_def] = File.expand_path("./graphs.json")
opt[:prefix]    = nil

graph_defs      = nil

opts = GetoptLong.new(
  [ '--dest',            GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--dir',       '-d', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--graph-def', '-g', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--help',      '-h', GetoptLong::NO_ARGUMENT       ],
  [ '--prefix',    '-p', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--version',   '-v', GetoptLong::NO_ARGUMENT       ]
)

opts.each do |o, arg|
  case o
    when '--dest'
      if File.directory?(arg)
        opt[:dest] = arg
      else
        puts "#{arg} is not a valid directory"
        usage
      end
    when '--dir'
      if File.directory?(arg)
        opt[:dir] = arg
      else
        puts "#{arg} is not a valid directory"
        usage
      end
    when '--graph-def'
      if File.exists?(arg)
        opt[:graph_def] = arg
      else
        puts "#{arg} does not exist"
        usage
      end
    when '--help'
      usage
    when '--prefix'
      opt[:prefix] = arg
    when '--version'
      puts "stalk2graph.rb 0.0.1"
      exit
  end
end

if opt[:prefix].nil?
  puts "--prefix is a required argument"
  usage
end

if !File.exists?(opt[:graph_def])
  puts "--graph-def option requires a valid JSON file"
  usage
else
  graph_def_file = File.open(File.expand_path(opt[:graph_def]))
  graph_json_data = graph_def_file.read
  graph_defs = JSON.parse(graph_json_data)
end

# Although some may be unused, these are hashes for all of the default pt-stalk
# output.
df             = {}
disk_space     = {}
diskstats      = {}
hostname       = {}
innodbstatus1  = {}
innodbstatus2  = {}
interrupts     = {}
lock_waits     = {}
lsof           = {}
meminfo        = {}
mutex_status1  = {}
mutex_status2  = {}
mysqladmin     = {}
netstat        = {}
netstat_s      = {}
opentables1    = {}
opentables2    = {}
output         = {}
pmap           = {}
processlist    = {}
procstat       = {}
procvmstat     = {}
ps             = {}
slabinfo       = {}
sysctl         = {}
top            = {}
transactions   = {}
trigger        = {}
variables      = {}
vmstat         = {}
vmstat_overall = {}


################################################################################
# Output from SHOW GLOBAL STATUS
################################################################################
mysqladmin_file = File.open(File.join(opt[:dir], "#{opt[:prefix]}-mysqladmin")).read
mysqladmin_file.each_line do |line|
  a = line.split(/\s+/)
  if a.length == 5 && a[1] != 'Variable_name'
    if mysqladmin.has_key?(a[1])
      mysqladmin[a[1]] << a[3]
    else
      mysqladmin[a[1]] = []
      mysqladmin[a[1]] << a[3]
    end
  end
end

################################################################################
# Output from SHOW GLOBAL VARIABLES
#
# We don't *expect* these to change during a capture, but they might
################################################################################
variables_file = File.open(File.join(opt[:dir], "#{opt[:prefix]}-variables")).read
variables_file.each_line do |line|
  a = line.split(/\s+/)
  if a[0] != 'Variable_name'
    if variables.has_key?(a[0])
      variables[a[0]] << a[1]
    else
      variables[a[0]] = []
      variables[a[0]] << a[1]
    end
  end
end

def generate_graphs_from_json(graph_def, dest)
  # Check the target file doesn't exist

  iterations = 0

  graph_def["data"].each do |k,v|
    puts mysqladmin[k]
    print v["display"] + ","
    if v["file"] == "mysqladmin"
      if iterations == 0
        iterations = mysqladmin[k].length
      elsif iterations > mysqladmin[k].length
        iterations = mysqladmin[k].length 
      end
    end
  end
  puts ""

  puts iterations

  # Find the lowest common denominator for how many results (and report it)
  # Cycle through that number and ..
  #graph_def["data"].each do |k,v|

  #end
end

# Generate a graph for each graph definition
#graph_defs.each do |g|
#  generate_graphs_from_json(g, opt[:dest])
#end

puts "Select,Delete,Insert,Update,Replace,Load,Delete Multi,Insert Select,Update Multi,Replace Select"

begin
  for i in 1..(mysqladmin["Com_select"].length)
    print mysqladmin["Com_select"][i] + ","
    print mysqladmin["Com_delete"][i] + ","
    print mysqladmin["Com_insert"][i] + ","
    print mysqladmin["Com_update"][i] + ","
    print mysqladmin["Com_replace"][i] + ","
    print mysqladmin["Com_load"][i] + ","
    print mysqladmin["Com_delete_multi"][i] + ","
    print mysqladmin["Com_insert_select"][i] + ","
    print mysqladmin["Com_update_multi"][i] + ","
    puts  mysqladmin["Com_replace_select"][i]
  end
rescue

end
