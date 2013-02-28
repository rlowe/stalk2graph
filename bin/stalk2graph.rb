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
opt[:prefix]    = nil

opts = GetoptLong.new(
  [ '--dest',            GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--dir',       '-d', GetoptLong::OPTIONAL_ARGUMENT ],
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
      opt[:dir] = arg
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

if !File.directory?(opt[:dir])
  puts "#{opt[:dir]} is not a valid directory"
  usage
end

opt[:dir] = File.expand_path(opt[:dir])

# Check for at least a single pt-stalk file and assume the rest are there
if !File.exists?(File.expand_path(opt[:dir], "#{opt[:prefix]}-df"))
  puts "Invalid --dir or --prefix."
  usage
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

#puts "#{`date`} - Processing pt-stalk files..."

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
    variables[a[0]] = a[1]
  end
end

#puts "#{`date`} - Generating .csv files..."

################################################################################
# Generate the data for the MySQL Command Counters Graph
################################################################################
File.open(File.expand_path("command_counters.csv", opt[:dest]), "w") do |f|
  f.write "select,delete,insert,update,replace,load,delete_multi,"
  f.write "insert_select,update_multi,replace_select\n"

  begin
    for i in 1..(mysqladmin["Com_select"].length)
      f.write mysqladmin["Com_select"][i] + ","
      f.write mysqladmin["Com_delete"][i] + ","
      f.write mysqladmin["Com_insert"][i] + ","
      f.write mysqladmin["Com_update"][i] + ","
      f.write mysqladmin["Com_replace"][i] + ","
      f.write mysqladmin["Com_load"][i] + ","
      f.write mysqladmin["Com_delete_multi"][i] + ","
      f.write mysqladmin["Com_insert_select"][i] + ","
      f.write mysqladmin["Com_update_multi"][i] + ","
      f.write mysqladmin["Com_replace_select"][i] + "\n"
    end
  rescue
    # We have this because sometimes Com_select has more records than Com_load
    # So this just stops the for loop at the minimum without having to check each 
    # array for length
  end
end

################################################################################
# Generate the data for the MySQL Handlers Graph
################################################################################
File.open(File.expand_path("handlers.csv", opt[:dest]), "w") do |f|
  f.write "write,update,delete,read_first,read_key,read_last,"
  f.write "read_next,read_prev,read_rnd,read_rnd_next\n"

  begin
    for i in 1..(mysqladmin["Handler_write"].length)
      f.write mysqladmin["Handler_write"][i] + ","
      f.write mysqladmin["Handler_update"][i] + ","
      f.write mysqladmin["Handler_delete"][i] + ","
      f.write mysqladmin["Handler_read_first"][i] + ","
      f.write mysqladmin["Handler_read_key"][i] + ","
      f.write mysqladmin["Handler_read_last"][i] + ","
      f.write mysqladmin["Handler_read_next"][i] + ","
      f.write mysqladmin["Handler_read_prev"][i] + ","
      f.write mysqladmin["Handler_read_rnd"][i] + ","
      f.write mysqladmin["Handler_read_rnd_next"][i] + "\n"
    end
  rescue
    # We have this because sometimes Com_select has more records than Com_load
    # So this just stops the for loop at the minimum without having to check each 
    # array for length
  end
end

################################################################################
# Generate the data for the MySQL Select Types Graph
################################################################################
File.open(File.expand_path("select_types.csv", opt[:dest]), "w") do |f|
  f.write "full_join,full_range_join,range,range_check,scan\n"

  begin
    for i in 1..(mysqladmin["Select_full_join"].length)
      f.write mysqladmin["Select_full_join"][i] + ","
      f.write mysqladmin["Select_full_range_join"][i] + ","
      f.write mysqladmin["Select_range"][i] + ","
      f.write mysqladmin["Select_range_check"][i] + ","
      f.write mysqladmin["Select_scan"][i] + "\n"
    end
  rescue
    # We have this because sometimes Com_select has more records than Com_load
    # So this just stops the for loop at the minimum without having to check each 
    # array for length
  end
end

################################################################################
# Generate the data for the MySQL Sorts Graph
################################################################################
File.open(File.expand_path("sorts.csv", opt[:dest]), "w") do |f|
  f.write "merge_passes,range,rows,scan\n"

  begin
    for i in 1..(mysqladmin["Sort_scan"].length)
      f.write mysqladmin["Sort_merge_passes"][i] + ","
      f.write mysqladmin["Sort_range"][i] + ","
      f.write mysqladmin["Sort_rows"][i] + ","
      f.write mysqladmin["Sort_scan"][i] + "\n"
    end
  rescue
    # We have this because sometimes Com_select has more records than Com_load
    # So this just stops the for loop at the minimum without having to check each 
    # array for length
  end
end

################################################################################
# Generate the data for the MySQL Transaction Handlers Graph
################################################################################
File.open(File.expand_path("transaction_handlers.csv", opt[:dest]), "w") do |f|
  f.write "commit,rollback,savepoint,savepoint_rollback\n"

  begin
    for i in 1..(mysqladmin["Handler_savepoint_rollback"].length)
      f.write mysqladmin["Handler_commit"][i] + ","
      f.write mysqladmin["Handler_rollback"][i] + ","
      f.write mysqladmin["Handler_savepoint"][i] + ","
      f.write mysqladmin["Handler_savepoint_rollback"][i] + "\n"
    end
  rescue
    # We have this because sometimes Com_select has more records than Com_load
    # So this just stops the for loop at the minimum without having to check each 
    # array for length
  end
end

################################################################################
# Generate the data for the MySQL InnoDB Adaptive Hash Searches Graph
################################################################################
File.open(File.expand_path("innodb_adaptive_hash_searches.csv", opt[:dest]), "w") do |f|
  f.write "hash_searches,non_hash_searches\n"

  begin
    for i in 1..(mysqladmin["Innodb_adaptive_hash_hash_searches"].length)
      f.write mysqladmin["Innodb_adaptive_hash_hash_searches"][i] + ","
      f.write mysqladmin["Innodb_adaptive_hash_non_hash_searches"][i] + "\n"
    end
  rescue
    # We have this because sometimes Com_select has more records than Com_load
    # So this just stops the for loop at the minimum without having to check each 
    # array for length
  end
end

################################################################################
# Generate the data for the InnoDB Buffer Pool Graph
################################################################################
File.open(File.expand_path("innodb_buffer_pool.csv", opt[:dest]), "w") do |f|
  f.write "pool_size,database_pages,pages_free,modified_pages\n"

  begin
    for i in 1..(mysqladmin["Innodb_buffer_pool_pages_total"].length)
      f.write mysqladmin["Innodb_buffer_pool_pages_total"][i] + ","
      f.write mysqladmin["Innodb_buffer_pool_pages_data"][i] + ","
      f.write mysqladmin["Innodb_buffer_pool_pages_free"][i] + ","
      f.write mysqladmin["Innodb_buffer_pool_pages_dirty"][i] + "\n"
    end
  rescue
    # We have this because sometimes Com_select has more records than Com_load
    # So this just stops the for loop at the minimum without having to check each 
    # array for length
  end
end

################################################################################
# Generate the data for the InnoDB Buffer Pool Activity Graph
################################################################################
File.open(File.expand_path("innodb_buffer_pool_activity.csv", opt[:dest]), "w") do |f|
  f.write "pages_created,pages_read,pages_written\n"

  begin
    for i in 1..(mysqladmin["Innodb_pages_written"].length)
      f.write mysqladmin["Innodb_pages_created"][i] + ","
      f.write mysqladmin["Innodb_pages_read"][i] + ","
      f.write mysqladmin["Innodb_pages_written"][i] + "\n"
    end
  rescue
    # We have this because sometimes Com_select has more records than Com_load
    # So this just stops the for loop at the minimum without having to check each 
    # array for length
  end
end

################################################################################
# Generate the data for the InnoDB Checkpoint Graph
################################################################################
File.open(File.expand_path("innodb_checkpoint.csv", opt[:dest]), "w") do |f|
  f.write "age,max_age,target_age\n"

  begin
    for i in 1..(mysqladmin["Innodb_checkpoint_age"].length)
      f.write mysqladmin["Innodb_checkpoint_age"][i] + ","
      f.write mysqladmin["Innodb_checkpoint_max_age"][i] + ","
      f.write mysqladmin["Innodb_checkpoint_target_age"][i] + "\n"
    end
  rescue
    # We have this because sometimes Com_select has more records than Com_load
    # So this just stops the for loop at the minimum without having to check each 
    # array for length
  end
end

################################################################################
# Generate the data for the InnoDB Insert Buffer Graph
################################################################################
File.open(File.expand_path("innodb_insert_buffer.csv", opt[:dest]), "w") do |f|
  f.write "free_list,merged_delete_marks,merged_deletes,merged_inserts,merges\n"

  begin
    for i in 1..(mysqladmin["Innodb_ibuf_merges"].length)
      f.write mysqladmin["Innodb_ibuf_free_list"][i] + ","
      f.write mysqladmin["Innodb_ibuf_merged_delete_marks"][i] + ","
      f.write mysqladmin["Innodb_ibuf_merged_deletes"][i] + ","
      f.write mysqladmin["Innodb_ibuf_merged_inserts"][i] + ","
      f.write mysqladmin["Innodb_ibuf_merges"][i] + "\n"
    end
  rescue
    # We have this because sometimes Com_select has more records than Com_load
    # So this just stops the for loop at the minimum without having to check each 
    # array for length
  end
end

################################################################################
# Generate the data for the InnoDB I/O Graph
################################################################################
File.open(File.expand_path("innodb_io.csv", opt[:dest]), "w") do |f|
  f.write "file_reads,file_writes,log_writes,file_syncs\n"

  begin
    for i in 1..(mysqladmin["Innodb_data_fsyncs"].length)
      f.write mysqladmin["Innodb_data_reads"][i] + ","
      f.write mysqladmin["Innodb_data_writes"][i] + ","
      f.write mysqladmin["Innodb_log_writes"][i] + ","
      f.write mysqladmin["Innodb_data_fsyncs"][i] + "\n"
    end
  rescue
    # We have this because sometimes Com_select has more records than Com_load
    # So this just stops the for loop at the minimum without having to check each 
    # array for length
  end
end

################################################################################
# Generate the data for Connections
################################################################################
File.open(File.expand_path("connections.csv", opt[:dest]), "w") do |f|
  f.write "max_connections,max_used_connections,aborted_clients,aborted_connects,threads_connected\n"

  begin
    for i in 1..(mysqladmin["Max_used_connections"].length-1)
      f.write variables["max_connections"] + ","
      f.write mysqladmin["Max_used_connections"][i] + ","
      f.write mysqladmin["Aborted_clients"][i] + ","
      f.write mysqladmin["Aborted_connects"][i] + ","
      f.write mysqladmin["Threads_connected"][i] + "\n"
    end
  rescue
    # We have this because sometimes Com_select has more records than Com_load
    # So this just stops the for loop at the minimum without having to check each 
    # array for length
  end
end

################################################################################
# Go through each .R script and execute to make the graphs
################################################################################

#puts "#{`date`} - Generating graphs..."

`Rscript --no-save #{File.dirname(__FILE__)}/command_counters.R #{File.expand_path("command_counters.csv", opt[:dest])} #{File.expand_path("command_counters.png", opt[:dest])}`
`Rscript --no-save #{File.dirname(__FILE__)}/handlers.R #{File.expand_path("handlers.csv", opt[:dest])} #{File.expand_path("handlers.png", opt[:dest])}`
`Rscript --no-save #{File.dirname(__FILE__)}/innodb_adaptive_hash_searches.R #{File.expand_path("innodb_adaptive_hash_searches.csv", opt[:dest])} #{File.expand_path("innodb_adaptive_hash_searches.png", opt[:dest])}`
`Rscript --no-save #{File.dirname(__FILE__)}/innodb_buffer_pool.R #{File.expand_path("innodb_buffer_pool.csv", opt[:dest])} #{File.expand_path("innodb_buffer_pool.png", opt[:dest])}`
`Rscript --no-save #{File.dirname(__FILE__)}/innodb_buffer_pool_activity.R #{File.expand_path("innodb_buffer_pool_activity.csv", opt[:dest])} #{File.expand_path("innodb_buffer_pool_activity.png", opt[:dest])}`
`Rscript --no-save #{File.dirname(__FILE__)}/innodb_checkpoint.R #{File.expand_path("innodb_checkpoint.csv", opt[:dest])} #{File.expand_path("innodb_checkpoint.png", opt[:dest])}`
`Rscript --no-save #{File.dirname(__FILE__)}/select_types.R #{File.expand_path("select_types.csv", opt[:dest])} #{File.expand_path("select_types.png", opt[:dest])}`
`Rscript --no-save #{File.dirname(__FILE__)}/sorts.R #{File.expand_path("sorts.csv", opt[:dest])} #{File.expand_path("sorts.png", opt[:dest])}`
`Rscript --no-save #{File.dirname(__FILE__)}/transaction_handlers.R #{File.expand_path("transaction_handlers.csv", opt[:dest])} #{File.expand_path("transaction_handlers.png", opt[:dest])}`
`Rscript --no-save #{File.dirname(__FILE__)}/innodb_insert_buffer.R #{File.expand_path("innodb_insert_buffer.csv", opt[:dest])} #{File.expand_path("innodb_insert_buffer.png", opt[:dest])}`
`Rscript --no-save #{File.dirname(__FILE__)}/innodb_io.R #{File.expand_path("innodb_io.csv", opt[:dest])} #{File.expand_path("innodb_io.png", opt[:dest])}`
`Rscript --no-save #{File.dirname(__FILE__)}/connections.R #{File.expand_path("connections.csv", opt[:dest])} #{File.expand_path("connections.png", opt[:dest])}`

################################################################################
# Create an .html page with all the graphs
################################################################################
File.open(File.expand_path("#{opt[:prefix]}.html", opt[:dest]), "w") do |f|
  f.write("<html><head></head><body>")

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/command_counters.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/handlers.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_adaptive_hash_searches.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_buffer_pool.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_buffer_pool_activity.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_checkpoint.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/select_types.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/sorts.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/transaction_handlers.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_insert_buffer.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_io.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/connections.png' />")

  f.write("</html>")
end














