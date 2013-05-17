#!/usr/bin/ruby

require 'rubygems'
require 'getoptlong'
require 'json'
require 'pp' # For Debugging 

################################################################################
# mext2graph.rb - Convert pt-mext output into something easily graphable
#                 (i.e. .csv file readable by R)
#
# - Goal is to keep consistent with:
#   www.percona.com/doc/percona-monitoring-plugins/cacti/mysql-templates.html
# - Assumes pt-stalk version 2.1+
#
################################################################################

def usage
  puts "mext2graph.rb --prefix=<PREFIX> [OPTIONS]

--debug:
  Print additional debug information

--dest:
  Location the output will be stored.
  DEFAULT: `cwd`

-f, --file:
  Location of pt-mext output file.

-h, --help:
  show help and exit

-v, --version:
  display version information and exit
"
  exit
end

opt             = Hash.new
opt[:debug]     = false
opt[:dest]      = File.expand_path(".")
opt[:file]      = nil

opts = GetoptLong.new(
  [ '--debug',           GetoptLong::NO_ARGUMENT       ],
  [ '--dest',            GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--file',      '-f', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--help',      '-h', GetoptLong::NO_ARGUMENT       ],
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
    when '--file'
      opt[:file] = arg
    when '--help'
      usage
    when '--version'
      puts "mext2graph.rb 0.0.1"
      exit
  end
end

if !File.exist?(opt[:file])
  puts "#{opt[:file]} is not a valid directory"
  usage
end

opt[:file] = File.expand_path(opt[:file])

mysqladmin     = {}

################################################################################
# Output from SHOW GLOBAL STATUS
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Processing pt-mext ..."
end

mext_file = File.open(opt[:file]).read
mext_file.each_line do |line|
  a = line.split(/\s+/)
  mysqladmin[a[0]] = []
  2..a.length.each do |i|
    mysqladmin[a[0]] << a[i]
  end
end

################################################################################
# We have to behave differently based on versions :-(
################################################################################

mysql_version_full=variables['version'].match(/\d+\.\d+\.\d+/).to_s
mysql_version_major=variables['version'].match(/\d+\.\d+/).to_s

################################################################################
# Generate the data for the MySQL Command Counters Graph
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for Command Counters ..."
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
  puts "#{`date`.chomp} - Generating .csv file for MySQL Handlers ..."
end

File.open(File.expand_path("handlers.csv", opt[:dest]), "w") do |f|
  f.write "write,update,delete,read_first,read_key,"
  if mysql_version_major == '5.5'
    f.write "read_last,"
  end
  f.write "read_next,read_prev,read_rnd,read_rnd_next\n"

  for i in 1..(mysqladmin["Handler_write"].length-1)
    f.write mysqladmin["Handler_write"][i] + ","
    f.write mysqladmin["Handler_update"][i] + ","
    f.write mysqladmin["Handler_delete"][i] + ","
    f.write mysqladmin["Handler_read_first"][i] + ","
    f.write mysqladmin["Handler_read_key"][i] + ","
    if mysql_version_major == '5.5'
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
  puts "#{`date`.chomp} - Generating .csv file for MySQL Select Types ..."
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
  puts "#{`date`.chomp} - Generating .csv file for MySQL Sorts ..."
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
  puts "#{`date`.chomp} - Generating .csv file for MySQL Transaction Handlers ..."
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
  puts "#{`date`.chomp} - Generating .csv file for MySQL InnoDB Adaptive Hash Searches ..."
end

innodb_adaptive_hash_searches=true

if mysqladmin["Innodb_adaptive_hash_hash_searches"]
  File.open(File.expand_path("innodb_adaptive_hash_searches.csv", opt[:dest]), "w") do |f|
    f.write "hash_searches,non_hash_searches\n"

    for i in 1..(mysqladmin["Innodb_adaptive_hash_hash_searches"].length-1)
      f.write mysqladmin["Innodb_adaptive_hash_hash_searches"][i] + ","
      f.write mysqladmin["Innodb_adaptive_hash_non_hash_searches"][i] + "\n"
    end
  end
else
  innodb_adaptive_hash_searches=false
end

################################################################################
# Generate the data for the InnoDB Buffer Pool Graph
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for MySQL InnoDB Buffer Pool ..."
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
  puts "#{`date`.chomp} - Generating .csv file for MySQL InnoDB Buffer Pool Activity ..."
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
  puts "#{`date`.chomp} - Generating .csv file for MySQL InnoDB Insert Buffer ..."
end

innodb_ibuf = true

if mysqladmin["Innodb_ibuf_merges"]
  File.open(File.expand_path("innodb_insert_buffer.csv", opt[:dest]), "w") do |f|
    f.write "free_list,merged_delete_marks,merged_deletes,merged_inserts,merges\n"

    for i in 1..(mysqladmin["Innodb_ibuf_merges"].length-1)
      f.write mysqladmin["Innodb_ibuf_free_list"][i] + ","
      f.write mysqladmin["Innodb_ibuf_merged_delete_marks"][i] + ","
      f.write mysqladmin["Innodb_ibuf_merged_deletes"][i] + ","
      f.write mysqladmin["Innodb_ibuf_merged_inserts"][i] + ","
      f.write mysqladmin["Innodb_ibuf_merges"][i] + "\n"
    end
  end
else
  innodb_ibuf = false
end

################################################################################
# Generate the data for the InnoDB I/O Graph
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for MySQL InnoDB I/O Graph ..."
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
#
#if opt[:debug]
#  puts "#{`date`.chomp} - Generating .csv file for MySQL Connections ..."
#end
#
#File.open(File.expand_path("connections.csv", opt[:dest]), "w") do |f|
#  f.write "max_connections,max_used_connections,aborted_clients,aborted_connects,threads_connected\n"
#
#  begin
#    for i in 1..(mysqladmin["Max_used_connections"].length-1)
#      f.write variables["max_connections"] + ","
#      f.write mysqladmin["Max_used_connections"][i] + ","
#      f.write mysqladmin["Aborted_clients"][i] + ","
#      f.write mysqladmin["Aborted_connects"][i] + ","
#      f.write mysqladmin["Threads_connected"][i] + "\n"
#    end
#  rescue
#    # We have this because sometimes Com_select has more records than Com_load
#    # So this just stops the for loop at the minimum without having to check each 
#    # array for length
#  end
#end

################################################################################
# Generate the data for MySQL network traffic
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for MySQL Network Traffic ..."
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
  puts "#{`date`.chomp} - Generating .csv file for MySQL Table Locks ..."
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
  puts "#{`date`.chomp} - Generating .csv file for MySQL Query Cache ..."
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
#
#if opt[:debug]
#  puts "#{`date`.chomp} - Generating .csv file for MySQL Query Cache Memory ..."
#end
#
#File.open(File.expand_path("query_cache_memory.csv", opt[:dest]), "w") do |f|
#  f.write "cache_size,free_blocks,free_memory,total_blocks\n"
#
#  for i in 1..(mysqladmin["Qcache_free_blocks"].length-1)
#    f.write variables["query_cache_size"] + ","
#    f.write mysqladmin["Qcache_free_blocks"][i] + ","
#    f.write mysqladmin["Qcache_free_memory"][i] + ","
#    f.write mysqladmin["Qcache_total_blocks"][i] + "\n"
#  end
#
#end

################################################################################
# Generate the data for Binary Log Cache
################################################################################
#
#if opt[:debug]
#  puts "#{`date`.chomp} - Generating .csv file for Binary Log Cache ..."
#end
#
#File.open(File.expand_path("binlog_cache.csv", opt[:dest]), "w") do |f|
#  f.write "cache_size,cache_use,cache_disk_use\n"
#
#  for i in 1..(mysqladmin["Binlog_cache_use"].length-1)
#    f.write variables["binlog_cache_size"] + ","
#    f.write mysqladmin["Binlog_cache_use"][i] + ","
#    f.write mysqladmin["Binlog_cache_disk_use"][i] + "\n"
#  end
#
#end

################################################################################
# Generate the data for Table Definitions
################################################################################
#
#if opt[:debug]
#  puts "#{`date`.chomp} - Generating .csv file for Table Definitions ..."
#end
#
#table_definitions = true
#
#if mysqladmin["Opened_table_definitions"]
#  File.open(File.expand_path("table_definitions.csv", opt[:dest]), "w") do |f|
#    f.write "definition_cache,open_table_defs,opened_table_defs\n"
#
#    for i in 1..(mysqladmin["Opened_table_definitions"].length-1)
#      f.write variables["table_definition_cache"] + ","
#      f.write mysqladmin["Open_table_definitions"][i] + ","
#      f.write mysqladmin["Opened_table_definitions"][i] + "\n"
#    end
#  end
#else
#  table_definitions = false
#end

################################################################################
# Generate the data for Files and Tables
################################################################################
#
#if opt[:debug]
#  puts "#{`date`.chomp} - Generating .csv file for Files and Tables ..."
#end
#
#tc = "table_open_cache"
#
#if mysql_version_major == '5.0'
#  tc = "table_cache"
#end
#
#File.open(File.expand_path("files_and_tables.csv", opt[:dest]), "w") do |f|
#  f.write "table_cache,open_tables,open_files,opened_tables\n"
#
#  for i in 1..(mysqladmin["Opened_tables"].length-1)
#    f.write variables[tc] + ","
#    f.write mysqladmin["Open_tables"][i] + ","
#    f.write mysqladmin["Open_files"][i] + ","
#    f.write mysqladmin["Opened_tables"][i] + "\n"
#  end
#
#end

################################################################################
# Generate the data for MyISAM Key Cache
################################################################################
#
#if opt[:debug]
#  puts "#{`date`.chomp} - Generating .csv file for MyISAM Key Cache ..."
#end
#
#File.open(File.expand_path("myisam_key_cache.csv", opt[:dest]), "w") do |f|
#  f.write "key_buffer_size,blocks_used,blocks_not_flushed\n"
#
#  for i in 1..(mysqladmin["Key_blocks_not_flushed"].length-1)
#    f.write variables["key_buffer_size"] + ","
#    f.write mysqladmin["Key_blocks_used"][i] + ","
#    f.write mysqladmin["Key_blocks_not_flushed"][i] + "\n"
#  end
#
#end

################################################################################
# Generate the data for MyISAM Indexes
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for MyISAM Indexes ..."
end

File.open(File.expand_path("myisam_indexes.csv", opt[:dest]), "w") do |f|
  f.write "read_requests,reads,write_requests,writes\n"

  for i in 1..(mysqladmin["Key_read_requests"].length-1)
    f.write mysqladmin["Key_read_requests"][i] + ","
    f.write mysqladmin["Key_reads"][i] + ","
    f.write mysqladmin["Key_write_requests"][i] + ","
    f.write mysqladmin["Key_writes"][i] + "\n"
  end

end

################################################################################
# Generate the data for Temp Tables
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for Temp Tables ..."
end

File.open(File.expand_path("temp_tables.csv", opt[:dest]), "w") do |f|
  f.write "tmp_tables,tmp_disk_tables\n"

  for i in 1..(mysqladmin["Created_tmp_tables"].length-1)
    f.write mysqladmin["Created_tmp_tables"][i] + ","
    f.write mysqladmin["Created_tmp_disk_tables"][i] + "\n"
  end

end

################################################################################
# Generate the data for InnoDB Checkpoint Age
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for InnoDB Checkpoint Age ..."
end

if mysqladmin["Innodb_checkpoint_age"]
  File.open(File.expand_path("innodb_checkpoint_age.csv", opt[:dest]), "w") do |f|
    f.write "max_age,target_age,age\n"

    for i in 1..(mysqladmin["Innodb_checkpoint_age"].length-1)
      f.write mysqladmin["Innodb_checkpoint_max_age"][i] + ","
      f.write mysqladmin["Innodb_checkpoint_target_age"][i] + ","
      f.write mysqladmin["Innodb_checkpoint_age"][i] + "\n"
    end
  end
end

################################################################################
# Generate the data for InnoDB Row Lock Waits
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for InnoDB Row Lock Waits ..."
end

File.open(File.expand_path("innodb_row_lock_waits.csv", opt[:dest]), "w") do |f|
  f.write "waits\n"

  for i in 1..(mysqladmin["Innodb_row_lock_waits"].length-1)
    f.write mysqladmin["Innodb_row_lock_waits"][i] + "\n"
  end
end

################################################################################
# Generate the data for InnoDB Row Lock Time
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for InnoDB Row Lock Time ..."
end

File.open(File.expand_path("innodb_row_lock_time.csv", opt[:dest]), "w") do |f|
  f.write "time\n"

  for i in 1..(mysqladmin["Innodb_row_lock_time"].length-1)
    f.write mysqladmin["Innodb_row_lock_time"][i] + "\n"
  end
end

################################################################################
# Generate the data for Thread Cache
################################################################################
#
#if opt[:debug]
#  puts "#{`date`.chomp} - Generating .csv file for Thread Cache ..."
#end
#
#File.open(File.expand_path("thread_cache.csv", opt[:dest]), "w") do |f|
#  f.write "cache_size,threads_created,threads_cached\n"
#
#  for i in 1..(mysqladmin["Threads_created"].length-1)
#    f.write variables["thread_cache_size"] + ","
#    f.write mysqladmin["Threads_created"][i] + ","
#    f.write mysqladmin["Threads_cached"][i] + "\n"
#  end
#end

################################################################################
# Go through each .R script and execute to make the graphs
################################################################################

puts "#{`date`.chomp} - Running command_counters.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/command_counters.R #{File.expand_path("command_counters.csv", opt[:dest])} #{File.expand_path("command_counters.png", opt[:dest])}`
puts "#{`date`.chomp} - Running processlist_states.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/processlist_states.R #{File.expand_path("processlist_states.csv", opt[:dest])} #{File.expand_path("processlist_states.png", opt[:dest])}`
if mysql_version_major == '5.5'
  puts "#{`date`.chomp} - Running handler55.R" if opt[:debug]
  `Rscript --no-save #{File.dirname(__FILE__)}/handlers55.R #{File.expand_path("handlers.csv", opt[:dest])} #{File.expand_path("handlers.png", opt[:dest])}`
elsif mysql_version_major == '5.1'
  puts "#{`date`.chomp} - Running handler51.R" if opt[:debug]
  `Rscript --no-save #{File.dirname(__FILE__)}/handlers51.R #{File.expand_path("handlers.csv", opt[:dest])} #{File.expand_path("handlers.png", opt[:dest])}`
else
  puts "WTF?!?!"
end

if innodb_adaptive_hash_searches
  puts "#{`date`.chomp} - Running innodb_adaptive_hash_searches.R" if opt[:debug]
  `Rscript --no-save #{File.dirname(__FILE__)}/innodb_adaptive_hash_searches.R #{File.expand_path("innodb_adaptive_hash_searches.csv", opt[:dest])} #{File.expand_path("innodb_adaptive_hash_searches.png", opt[:dest])}`
else
  puts "#{`date`.chomp}.chomp - Skipping InnoDB Adaptive Hash Searches ..." if opt[:debug]
end

puts "#{`date`.chomp} - Running innodb_buffer_pool.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/innodb_buffer_pool.R #{File.expand_path("innodb_buffer_pool.csv", opt[:dest])} #{File.expand_path("innodb_buffer_pool.png", opt[:dest])}`
puts "#{`date`.chomp} - Running innodb_buffer_pool_activity.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/innodb_buffer_pool_activity.R #{File.expand_path("innodb_buffer_pool_activity.csv", opt[:dest])} #{File.expand_path("innodb_buffer_pool_activity.png", opt[:dest])}`

puts "#{`date`.chomp} - Running select_types.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/select_types.R #{File.expand_path("select_types.csv", opt[:dest])} #{File.expand_path("select_types.png", opt[:dest])}`
puts "#{`date`.chomp} - Running sorts.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/sorts.R #{File.expand_path("sorts.csv", opt[:dest])} #{File.expand_path("sorts.png", opt[:dest])}`
puts "#{`date`.chomp} - Running transaction_handlers.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/transaction_handlers.R #{File.expand_path("transaction_handlers.csv", opt[:dest])} #{File.expand_path("transaction_handlers.png", opt[:dest])}`

if innodb_ibuf
  puts "#{`date`.chomp} - Running innodb_insert_buffer.R" if opt[:debug]
  `Rscript --no-save #{File.dirname(__FILE__)}/innodb_insert_buffer.R #{File.expand_path("innodb_insert_buffer.csv", opt[:dest])} #{File.expand_path("innodb_insert_buffer.png", opt[:dest])}`
else
  puts "#{`date`.chomp} - Skipping InnoDB Insert Buffer ..." if opt[:debug]
end

puts "#{`date`.chomp} - Running innodb_io.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/innodb_io.R #{File.expand_path("innodb_io.csv", opt[:dest])} #{File.expand_path("innodb_io.png", opt[:dest])}`
puts "#{`date`.chomp} - Running connections.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/connections.R #{File.expand_path("connections.csv", opt[:dest])} #{File.expand_path("connections.png", opt[:dest])}`
puts "#{`date`.chomp} - Running mysql_network_traffic.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/mysql_network_traffic.R #{File.expand_path("mysql_network_traffic.csv", opt[:dest])} #{File.expand_path("mysql_network_traffic.png", opt[:dest])}`
puts "#{`date`.chomp} - Running table_locks.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/table_locks.R #{File.expand_path("table_locks.csv", opt[:dest])} #{File.expand_path("table_locks.png", opt[:dest])}`
puts "#{`date`.chomp} - Running query_cache.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/query_cache.R #{File.expand_path("query_cache.csv", opt[:dest])} #{File.expand_path("query_cache.png", opt[:dest])}`
puts "#{`date`.chomp} - Running query_cache_memory.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/query_cache_memory.R #{File.expand_path("query_cache_memory.csv", opt[:dest])} #{File.expand_path("query_cache_memory.png", opt[:dest])}`
puts "#{`date`.chomp} - Running binlog_cache.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/binlog_cache.R #{File.expand_path("binlog_cache.csv", opt[:dest])} #{File.expand_path("binlog_cache.png", opt[:dest])}`

if table_definitions
  puts "#{`date`.chomp} - Running table_definitions.R" if opt[:debug]
  `Rscript --no-save #{File.dirname(__FILE__)}/table_definitions.R #{File.expand_path("table_definitions.csv", opt[:dest])} #{File.expand_path("table_definitions.png", opt[:dest])}`
else
  puts "#{`date`.chomp} - Skipping Table Definitions ..." if opt[:debug]
end

puts "#{`date`.chomp} - Running files_and_tables.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/files_and_tables.R #{File.expand_path("files_and_tables.csv", opt[:dest])} #{File.expand_path("files_and_tables.png", opt[:dest])}`

puts "#{`date`.chomp} - Running myisam_key_cache.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/myisam_key_cache.R #{File.expand_path("myisam_key_cache.csv", opt[:dest])} #{File.expand_path("myisam_key_cache.png", opt[:dest])}`

puts "#{`date`.chomp} - Running myisam_indexes.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/myisam_indexes.R #{File.expand_path("myisam_indexes.csv", opt[:dest])} #{File.expand_path("myisam_indexes.png", opt[:dest])}`

puts "#{`date`.chomp} - Running temp_tables.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/temp_tables.R #{File.expand_path("temp_tables.csv", opt[:dest])} #{File.expand_path("temp_tables.png", opt[:dest])}`

if mysqladmin["Innodb_checkpoint_age"]
  puts "#{`date`.chomp} - Running innodb_checkpoint_age.R" if opt[:debug]
  `Rscript --no-save #{File.dirname(__FILE__)}/innodb_checkpoint_age.R #{File.expand_path("innodb_checkpoint_age.csv", opt[:dest])} #{File.expand_path("innodb_checkpoint_age.png", opt[:dest])}`
end

puts "#{`date`.chomp} - Running innodb_row_lock_waits.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/innodb_row_lock_waits.R #{File.expand_path("innodb_row_lock_waits.csv", opt[:dest])} #{File.expand_path("innodb_row_lock_waits.png", opt[:dest])}`

puts "#{`date`.chomp} - Running innodb_row_lock_time.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/innodb_row_lock_time.R #{File.expand_path("innodb_row_lock_time.csv", opt[:dest])} #{File.expand_path("innodb_row_lock_time.png", opt[:dest])}`

puts "#{`date`.chomp} - Running thread_cache.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/thread_cache.R #{File.expand_path("thread_cache.csv", opt[:dest])} #{File.expand_path("thread_cache.png", opt[:dest])}`

################################################################################
# Create an .html page with all the graphs
################################################################################
File.open(File.expand_path("#{opt[:prefix]}.html", opt[:dest]), "w") do |f|
  f.write("<html><head></head><body>")

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/command_counters.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/handlers.png' />")

  if innodb_adaptive_hash_searches
    f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_adaptive_hash_searches.png' />")
  end

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_buffer_pool.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_buffer_pool_activity.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/select_types.png' />")

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/sorts.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/transaction_handlers.png' />")

  if innodb_ibuf
    f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_insert_buffer.png' />")
  end

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_io.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/connections.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/mysql_network_traffic.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/table_locks.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/query_cache.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/query_cache_memory.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/binlog_cache.png' />")

  if table_definitions
    f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/table_definitions.png' />")
  end

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/files_and_tables.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/myisam_key_cache.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/myisam_indexes.png' />")

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/temp_tables.png' />")

  if mysqladmin["Innodb_checkpoint_age"]
    f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_checkpoint_age.png' />")
  end

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_row_lock_waits.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/innodb_row_lock_time.png' />")

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/thread_cache.png' />")

  f.write("</html>")
end
