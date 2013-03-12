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

--debug:
  Print additional debug information

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
opt[:debug]     = false
opt[:dest]      = File.expand_path(".")
opt[:dir]       = "/var/lib/pt-stalk/"
opt[:prefix]    = nil

opts = GetoptLong.new(
  [ '--debug',           GetoptLong::NO_ARGUMENT       ],
  [ '--dest',            GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--dir',       '-d', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--help',      '-h', GetoptLong::NO_ARGUMENT       ],
  [ '--prefix',    '-p', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--version',   '-v', GetoptLong::NO_ARGUMENT       ]
)

opts.each do |o, arg|
  case o
    when '--debug'
      opt[:debug] = true
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

################################################################################
# Output from SHOW GLOBAL STATUS
################################################################################

if opt[:debug]
  puts "#{`date`} - Processing pt-stalk mysqladmin ..."
end

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
# We expect only one set of results for an entire capture
################################################################################

if opt[:debug]
  puts "#{`date`} - Processing pt-stalk variables ..."
end

variables_file = File.open(File.join(opt[:dir], "#{opt[:prefix]}-variables")).read
variables_file.each_line do |line|
  a = line.split(/\s+/)
  if a[0] != 'Variable_name'
    variables[a[0]] = a[1]
  end
end

################################################################################
# We have to behave differently based on versions :-(
################################################################################
MYSQL_VERSION_FULL=variables['version'].match(/\d+\.\d+\.\d+/).to_s
MYSQL_VERSION_MAJOR=variables['version'].match(/\d+\.\d+/).to_s

################################################################################
# Output from SHOW FULL PROCESSLIST
################################################################################

if opt[:debug]
  puts "#{`date`} - Processing pt-stalk processlist ..."
end

processlist_snapshots = 0
processlist_file = File.open(File.join(opt[:dir], "#{opt[:prefix]}-processlist")).read
processlist_states = [
  'After create',
  'Analyzing',
  'checking permissions',
  'Checking table',
  'cleaning up',
  'closing tables',
  'conevrting HEAP to MyISAM',
  'copy to tmp table',
  'Copying to group table',
  'Copying to tmp table',
  'Copying to tmp table on disk',
  'Creating index',
  'Creating sort index',
  'creating table',
  'Creating tmp table',
  'deleting from main table',
  'deleting from reference tables',
  'discard_or_import_tablespace',
  'end',
  'executing',
  'Execution of init_command',
  'freeing items',
  'Flushing tables',
  'FULLTEXT initialization',
  'init',
  'Killed',
  'Locked',
  'logging slow query', ## from here, below, they are wrong, just remove the symbol
  'NULL',
  'login',
  'manage keys',
  'Opening tables',
  'Opening table',
  'optimizing',
  'preparing',
  'Purging old relay logs',
  'query end',
  'Reading from net',
  'Removing duplicates',
  'removing tmp table',
  'rename',
  'rename result table',
  'Reopen tables',
  'Repair by sorting',
  'Repair done',
  'Repair with keycache',
  'Rolling back',
  'Saving state',
  'Searching rows for update',
  'Sending data',
  'setup',
  'Sorting for group',
  'Sorting for order',
  'Sorting index',
  'Sorting result',
  'statistics',
  'System lock',
  'Table lock',
  'Updating',
  'updating main table',
  'updating reference tables',
  'User lock',
  'User sleep',
  'Waiting for all running commits to finish',
  'Waiting for commit lock',
  'Waiting for global read lock',
  'Waiting for release of readlock',
  'Waiting for table',
  'Waiting for tables',
  'Waiting for table flush',
  'Waiting for event metadata lock',
  'Waiting for global metadata lock',
  'Waiting for global read lock',
  'Waiting for schema metadata lock',
  'Waiting for stored function metadata lock',
  'Waiting for stored procedure metadata lock',
  'Waiting for table level lock',
  'Waiting for table metadata lock',
  'Waiting for trigger metadata lock',
  'Waiting on cond',
  'Waiting to get readlock',
  'Writing to net',
  'Waiting for master to send event',
  'Slave has read all relay log; waiting for the slave I/O thread to update it',
  'Master has sent all binlog to slave; waiting for binlog to be updated'
]

processlist_file.each_line do |line|
  if line =~ /^TS [0-9][0-9]*/
    processlist_snapshots += 1
    processlist[processlist_snapshots] = {}
    processlist_states.each { |state|
      processlist[processlist_snapshots][state] = 0
    }
    processlist[processlist_snapshots][""] = 0
  elsif line =~ /^        State: /
    s = /[:](.*)$/.match(line)[0][1..-1].strip
    if processlist[processlist_snapshots].has_key? s
      processlist[processlist_snapshots][s] += 1
    else
      processlist[processlist_snapshots][s] = 1
    end
  end
end

################################################################################
# Generate the data for the MySQL Command Counters Graph
################################################################################

if opt[:debug]
  puts "#{`date`} - Generating .csv file for Command Counters ..."
end

if File.exists?(File.expand_path("command_counters.csv", opt[:dest]))
  File.delete(File.expand_path("command_counters.csv", opt[:dest]))
end

File.open(File.expand_path("command_counters.csv", opt[:dest]), "w") do |f|
  f.write "select,delete,insert,update,replace,load,delete_multi,"
  f.write "insert_select,update_multi,replace_select\n"

  for i in 1..(mysqladmin["Com_select"].length-1)
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
end

################################################################################
# Generate the data for the MySQL Handlers Graph
################################################################################

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL Handlers ..."
end

File.open(File.expand_path("handlers.csv", opt[:dest]), "w") do |f|
  f.write "write,update,delete,read_first,read_key,"
  if MYSQL_VERSION_MAJOR == '5.5'
    f.write "read_last,"
  end
  f.write "read_next,read_prev,read_rnd,read_rnd_next\n"

  for i in 1..(mysqladmin["Handler_write"].length-1)
    f.write mysqladmin["Handler_write"][i] + ","
    f.write mysqladmin["Handler_update"][i] + ","
    f.write mysqladmin["Handler_delete"][i] + ","
    f.write mysqladmin["Handler_read_first"][i] + ","
    f.write mysqladmin["Handler_read_key"][i] + ","
    if MYSQL_VERSION_MAJOR == '5.5'
      f.write mysqladmin["Handler_read_last"][i] + ","
    end
    f.write mysqladmin["Handler_read_next"][i] + ","
    f.write mysqladmin["Handler_read_prev"][i] + ","
    f.write mysqladmin["Handler_read_rnd"][i] + ","
    f.write mysqladmin["Handler_read_rnd_next"][i] + "\n"
  end
end

################################################################################
# Generate the data for the MySQL Select Types Graph
################################################################################

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL Select Types ..."
end

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

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL Sorts ..."
end

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

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL Transaction Handlers ..."
end

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
# This approach only works with Percona Server 5.5+
################################################################################

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL InnoDB Adaptive Hash Searches ..."
end

INNODB_ADAPTIVE_HASH_SEARCHES=true

if mysqladmin["Innodb_adaptive_hash_hash_searches"]
  File.open(File.expand_path("innodb_adaptive_hash_searches.csv", opt[:dest]), "w") do |f|
    f.write "hash_searches,non_hash_searches\n"

    for i in 1..(mysqladmin["Innodb_adaptive_hash_hash_searches"].length)
      f.write mysqladmin["Innodb_adaptive_hash_hash_searches"][i] + ","
      f.write mysqladmin["Innodb_adaptive_hash_non_hash_searches"][i] + "\n"
    end
  end
else
  INNODB_ADAPTIVE_HASH_SEARCHES=false
end

################################################################################
# Generate the data for the InnoDB Buffer Pool Graph
################################################################################

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL InnoDB Buffer Pool ..."
end

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

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL InnoDB Buffer Pool Activity ..."
end

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
# Generate the data for the InnoDB Insert Buffer Graph
################################################################################

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL InnoDB Insert Buffer ..."
end

INNODB_IBUF = true

if mysqladmin["Innodb_ibuf_merges"]
  File.open(File.expand_path("innodb_insert_buffer.csv", opt[:dest]), "w") do |f|
    f.write "free_list,merged_delete_marks,merged_deletes,merged_inserts,merges\n"

    for i in 1..(mysqladmin["Innodb_ibuf_merges"].length)
      f.write mysqladmin["Innodb_ibuf_free_list"][i] + ","
      f.write mysqladmin["Innodb_ibuf_merged_delete_marks"][i] + ","
      f.write mysqladmin["Innodb_ibuf_merged_deletes"][i] + ","
      f.write mysqladmin["Innodb_ibuf_merged_inserts"][i] + ","
      f.write mysqladmin["Innodb_ibuf_merges"][i] + "\n"
    end
  end
else
  INNODB_IBUF = false
end

################################################################################
# Generate the data for the InnoDB I/O Graph
################################################################################

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL InnoDB I/O Graph ..."
end

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

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL Connections ..."
end

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
# Generate the data for Processlist States
################################################################################

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL Processlist States ..."
end

File.open(File.expand_path("processlist_states.csv", opt[:dest]), "w") do |f|

    processlist_states.each { |state|
       delim = ","
       if state == processlist_states.last
         delim = "\n"
       end
       f.write state + delim
    }

  processlist.each do |capture, data|
    processlist_states.each { |state| 
      delim = ","
      if state == processlist_states.last
        delim = "\n"
      end
      f.write data[state].to_s + delim
    }
  end

end

################################################################################
# Generate the data for MySQL network traffic
################################################################################

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL Network Traffic ..."
end

File.open(File.expand_path("mysql_network_traffic.csv", opt[:dest]), "w") do |f|
  f.write "bytes_sent,bytes_received\n"

  begin
    for i in 1..(mysqladmin["Bytes_received"].length)
      f.write mysqladmin["Bytes_sent"][i] + ","
      f.write mysqladmin["Bytes_received"][i] + "\n"
    end
  rescue

  end
end

################################################################################
# Generate the data for table locks
################################################################################

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL Table Locks ..."
end

File.open(File.expand_path("table_locks.csv", opt[:dest]), "w") do |f|
  f.write "immediate,waited\n"

  begin
    for i in 1..(mysqladmin["Table_locks_waited"].length)
      f.write mysqladmin["Table_locks_immediate"][i] + ","
      f.write mysqladmin["Table_locks_waited"][i] + "\n"
    end
  rescue

  end
end

################################################################################
# Generate the data for Query Cache
################################################################################

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL Query Cache ..."
end

File.open(File.expand_path("query_cache.csv", opt[:dest]), "w") do |f|
  f.write "hits,inserts,lowmem_prunes,not_cached,queries_in_cache\n"

  begin
    for i in 1..(mysqladmin["Qcache_hits"].length)
      f.write mysqladmin["Qcache_hits"][i] + ","
      f.write mysqladmin["Qcache_inserts"][i] + ","
      f.write mysqladmin["Qcache_lowmem_prunes"][i] + ","
      f.write mysqladmin["Qcache_not_cached"][i] + ","
      f.write mysqladmin["Qcache_queries_in_cache"][i] + "\n"
    end
  rescue

  end
end

################################################################################
# Generate the data for Query Cache Memory
################################################################################

if opt[:debug]
  puts "#{`date`} - Generating .csv file for MySQL Query Cache Memory ..."
end

File.open(File.expand_path("query_cache_memory.csv", opt[:dest]), "w") do |f|
  f.write "cache_size,free_blocks,free_memory,total_blocks\n"

  for i in 1..(mysqladmin["Qcache_free_blocks"].length-1)
    f.write variables["query_cache_size"] + ","
    f.write mysqladmin["Qcache_free_blocks"][i] + ","
    f.write mysqladmin["Qcache_free_memory"][i] + ","
    f.write mysqladmin["Qcache_total_blocks"][i] + "\n"
  end

end

################################################################################
# Generate the data for Binary Log Cache
################################################################################

if opt[:debug]
  puts "#{`date`} - Generating .csv file for Binary Log Cache ..."
end

File.open(File.expand_path("binlog_cache.csv", opt[:dest]), "w") do |f|
  f.write "cache_size,cache_use,cache_disk_use\n"

  for i in 1..(mysqladmin["Binlog_cache_use"].length-1)
    f.write variables["binlog_cache_size"] + ","
    f.write mysqladmin["Binlog_cache_use"][i] + ","
    f.write mysqladmin["Binlog_cache_disk_use"][i] + "\n"
  end

end

################################################################################
# Go through each .R script and execute to make the graphs
################################################################################

#puts "#{`date`} - Running command_counters.R" if opt[:debug]
#`Rscript --no-save #{File.dirname(__FILE__)}/command_counters.R #{File.expand_path("command_counters.csv", opt[:dest])} #{File.expand_path("command_counters.png", opt[:dest])}`
#puts "#{`date`} - Running processlist_states.R" if opt[:debug]
#`Rscript --no-save #{File.dirname(__FILE__)}/processlist_states.R #{File.expand_path("processlist_states.csv", opt[:dest])} #{File.expand_path("processlist_states.png", opt[:dest])}`
#if MYSQL_VERSION_MAJOR == '5.5'
#  puts "#{`date`} - Running handler55.R" if opt[:debug]
#  `Rscript --no-save #{File.dirname(__FILE__)}/handlers55.R #{File.expand_path("handlers.csv", opt[:dest])} #{File.expand_path("handlers.png", opt[:dest])}`
#elsif MYSQL_VERSION_MAJOR == '5.1'
#  puts "#{`date`} - Running handler51.R" if opt[:debug]
#  `Rscript --no-save #{File.dirname(__FILE__)}/handlers51.R #{File.expand_path("handlers.csv", opt[:dest])} #{File.expand_path("handlers.png", opt[:dest])}`
#else
#  puts "WTF?!?!"
#end
#
#if INNODB_ADAPTIVE_HASH_SEARCHES
#  puts "#{`date`} - Running innodb_adaptive_hash_searches.R" if opt[:debug]
#  `Rscript --no-save #{File.dirname(__FILE__)}/innodb_adaptive_hash_searches.R #{File.expand_path("innodb_adaptive_hash_searches.csv", opt[:dest])} #{File.expand_path("innodb_adaptive_hash_searches.png", opt[:dest])}`
#else
#  puts "#{`date`}.chomp - Skipping InnoDB Adaptive Hash Searches ..." if opt[:debug]
#end
#
#puts "#{`date`} - Running innodb_buffer_pool.R" if opt[:debug]
#`Rscript --no-save #{File.dirname(__FILE__)}/innodb_buffer_pool.R #{File.expand_path("innodb_buffer_pool.csv", opt[:dest])} #{File.expand_path("innodb_buffer_pool.png", opt[:dest])}`
#puts "#{`date`} - Running innodb_buffer_pool_activity.R" if opt[:debug]
#`Rscript --no-save #{File.dirname(__FILE__)}/innodb_buffer_pool_activity.R #{File.expand_path("innodb_buffer_pool_activity.csv", opt[:dest])} #{File.expand_path("innodb_buffer_pool_activity.png", opt[:dest])}`
#
##puts "#{`date`} - Running innodb_checkpoint.R" if opt[:debug]
##`Rscript --no-save #{File.dirname(__FILE__)}/innodb_checkpoint.R #{File.expand_path("innodb_checkpoint.csv", opt[:dest])} #{File.expand_path("innodb_checkpoint.png", opt[:dest])}`
#
#puts "#{`date`} - Running select_types.R" if opt[:debug]
#`Rscript --no-save #{File.dirname(__FILE__)}/select_types.R #{File.expand_path("select_types.csv", opt[:dest])} #{File.expand_path("select_types.png", opt[:dest])}`
#puts "#{`date`} - Running sorts.R" if opt[:debug]
#`Rscript --no-save #{File.dirname(__FILE__)}/sorts.R #{File.expand_path("sorts.csv", opt[:dest])} #{File.expand_path("sorts.png", opt[:dest])}`
#puts "#{`date`} - Running transaction_handlers.R" if opt[:debug]
#`Rscript --no-save #{File.dirname(__FILE__)}/transaction_handlers.R #{File.expand_path("transaction_handlers.csv", opt[:dest])} #{File.expand_path("transaction_handlers.png", opt[:dest])}`
#
#if INNODB_IBUF
#  puts "#{`date`} - Running innodb_insert_buffer.R" if opt[:debug]
#  `Rscript --no-save #{File.dirname(__FILE__)}/innodb_insert_buffer.R #{File.expand_path("innodb_insert_buffer.csv", opt[:dest])} #{File.expand_path("innodb_insert_buffer.png", opt[:dest])}`
#else
#  puts "#{`date`} - Skipping InnoDB Insert Buffer ..." if opt[:debug]
#end
#
#puts "#{`date`} - Running innodb_io.R" if opt[:debug]
#`Rscript --no-save #{File.dirname(__FILE__)}/innodb_io.R #{File.expand_path("innodb_io.csv", opt[:dest])} #{File.expand_path("innodb_io.png", opt[:dest])}`
#puts "#{`date`} - Running connections.R" if opt[:debug]
#`Rscript --no-save #{File.dirname(__FILE__)}/connections.R #{File.expand_path("connections.csv", opt[:dest])} #{File.expand_path("connections.png", opt[:dest])}`
#puts "#{`date`} - Running mysql_network_traffic.R" if opt[:debug]
#`Rscript --no-save #{File.dirname(__FILE__)}/mysql_network_traffic.R #{File.expand_path("mysql_network_traffic.csv", opt[:dest])} #{File.expand_path("mysql_network_traffic.png", opt[:dest])}`
#puts "#{`date`} - Running table_locks.R" if opt[:debug]
#`Rscript --no-save #{File.dirname(__FILE__)}/table_locks.R #{File.expand_path("table_locks.csv", opt[:dest])} #{File.expand_path("table_locks.png", opt[:dest])}`
#puts "#{`date`} - Running query_cache.R" if opt[:debug]
#`Rscript --no-save #{File.dirname(__FILE__)}/query_cache.R #{File.expand_path("query_cache.csv", opt[:dest])} #{File.expand_path("query_cache.png", opt[:dest])}`
puts "#{`date`} - Running query_cache_memory.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/query_cache_memory.R #{File.expand_path("query_cache_memory.csv", opt[:dest])} #{File.expand_path("query_cache_memory.png", opt[:dest])}`
puts "#{`date`} - Running binlog_cache.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/binlog_cache.R #{File.expand_path("binlog_cache.csv", opt[:dest])} #{File.expand_path("binlog_cache.png", opt[:dest])}`

################################################################################
# Create an .html page with all the graphs
################################################################################
File.open(File.expand_path("#{opt[:prefix]}.html", opt[:dest]), "w") do |f|
  f.write("<html><head></head><body>")

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/command_counters.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/handlers.png' />")

  if INNODB_ADAPTIVE_HASH_SEARCHES
    f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_adaptive_hash_searches.png' />")
  end

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_buffer_pool.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_buffer_pool_activity.png' />")
  #f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_checkpoint.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/select_types.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/sorts.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/transaction_handlers.png' />")

  if INNODB_IBUF
    f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_insert_buffer.png' />")
  end

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_io.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/connections.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/mysql_network_traffic.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/table_locks.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/query_cache.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/query_cache_memory.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/binlog_cache.png' />")

  f.write("</html>")
end
