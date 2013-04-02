#!/usr/bin/ruby

require 'rubygems'
require 'getoptlong'
require 'json'
require 'pp' # For Debugging 

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
iostat         = {}
lock_waits     = {}
lsof           = {}
meminfo        = {}
mpstat         = {}
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
  puts "#{`date`.chomp} - Processing pt-stalk mysqladmin ..."
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
  puts "#{`date`.chomp} - Processing pt-stalk variables ..."
end

variables_file = File.open(File.join(opt[:dir], "#{opt[:prefix]}-variables")).read
variables_file.each_line do |line|
  a = line.split(/\s+/)
  if a[0] != 'Variable_name'
    variables[a[0]] = a[1]
  end
end

################################################################################
# Output from `mpstat`
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Processing mpstat output ..."
end

cores=0

mpstat_i=0

mpstat_file = File.open(File.join(opt[:dir], "#{opt[:prefix]}-mpstat")).read
mpstat_file.each_line do |line|
  if line.length != 1 && !line.include?('CPU') && !line.include?('Average') && !line.include?('Linux')
    a = line.split(/\s+/)

    if a[2].to_s == 'all'
      mpstat_i += 1
      mpstat[mpstat_i] = {}
    else
      if a[2].to_i > cores.to_i
        cores = a[2].to_i
      end
    end

    mpstat[mpstat_i][a[2]] = {}
    mpstat[mpstat_i][a[2]][:usr] = a[3]
    mpstat[mpstat_i][a[2]][:nice] = a[4]
    mpstat[mpstat_i][a[2]][:sys] = a[5]
    mpstat[mpstat_i][a[2]][:iowait] = a[6]
    mpstat[mpstat_i][a[2]][:irq] = a[7]
    mpstat[mpstat_i][a[2]][:soft] = a[8]
    mpstat[mpstat_i][a[2]][:steal] = a[9]
    mpstat[mpstat_i][a[2]][:guest] = a[10]
    mpstat[mpstat_i][a[2]][:idle] = a[11]

  end
end

################################################################################
# Output from meminfo
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Processing meminfo ..."
end

meminfo_file = File.open(File.join(opt[:dir], "#{opt[:prefix]}-meminfo")).read
meminfo_file.each_line do |line|
  a = line.split(/\s+/)

  if a[0] != 'TS'
    a0 = a[0][0..-2]
    if meminfo.has_key?(a0)
      meminfo[a0] << a[1]
    else
      meminfo[a0] = []
      meminfo[a0] << a[1]
    end

  end
end

################################################################################
# Output from iostat
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Processing iostat ..."
end

disks = Array.new

iostat_file = File.open(File.join(opt[:dir], "#{opt[:prefix]}-iostat")).read
iostat_file.each_line do |line|
  if line.length > 2
    a = line.split(/\s+/)
    if a[0] != 'Linux' && a[0] != 'Device:'
      if iostat.has_key?(a[0])
        iostat[a[0]][:rrqm] << a[1]
        iostat[a[0]][:wrqm] << a[2]
        iostat[a[0]][:r] << a[3]
        iostat[a[0]][:w] << a[4]
        iostat[a[0]][:rsec] << a[5]
        iostat[a[0]][:wsec] << a[6]
        iostat[a[0]][:avgrqsz] << a[7]
        iostat[a[0]][:avgqusz] << a[8]
        iostat[a[0]][:await] << a[9]
        iostat[a[0]][:svctm] << a[10]
      else
        iostat[a[0]] = {}
        iostat[a[0]][:rrqm] = []
        iostat[a[0]][:wrqm] = []
        iostat[a[0]][:r] = []
        iostat[a[0]][:w] = []
        iostat[a[0]][:rsec] = []
        iostat[a[0]][:wsec] = []
        iostat[a[0]][:avgrqsz] = []
        iostat[a[0]][:avgqusz] = []
        iostat[a[0]][:await] = []
        iostat[a[0]][:svctm] = []

        iostat[a[0]][:rrqm] << a[1]
        iostat[a[0]][:wrqm] << a[2]
        iostat[a[0]][:r] << a[3]
        iostat[a[0]][:w] << a[4]
        iostat[a[0]][:rsec] << a[5]
        iostat[a[0]][:wsec] << a[6]
        iostat[a[0]][:avgrqsz] << a[7]
        iostat[a[0]][:avgqusz] << a[8]
        iostat[a[0]][:await] << a[9]
        iostat[a[0]][:svctm] << a[10]
      end
    end
  end
end

################################################################################
# Output from netstat
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Processing netstat ..."
end

netstat_i = 0
netstat_j = 0

netstat_file = File.open(File.join(opt[:dir], "#{opt[:prefix]}-netstat")).read
netstat_file.each_line do |line|
  a = line.split(/\s+/)
  if a[0] == 'Active'
    netstat_i += 1
    netstat[netstat_i] = {}
    netstat_j = 1
    netstat[netstat_i][netstat_j] = {}
  elsif a[0] == 'TS' || a[0] == 'Proto'
    # Do Nothing
  else
    netstat[netstat_i][netstat_j][:proto] = a[0]
    netstat[netstat_i][netstat_j][:recvq] = a[1]
    netstat[netstat_i][netstat_j][:sendq] = a[2]
    netstat[netstat_i][netstat_j][:local_address] = a[3]
    netstat[netstat_i][netstat_j][:foreign_address] = a[4]
    netstat[netstat_i][netstat_j][:state] = a[5]
    netstat[netstat_i][netstat_j][:pid] = a[6]
    netstat_j += 1
    netstat[netstat_i][netstat_j] = {}
  end
end

################################################################################
# Output from vmstat
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Processing vmstat ..."
end

    vmstat[:r] = Array.new
    vmstat[:b] = Array.new
    vmstat[:swpd] = Array.new
    vmstat[:free] = Array.new
    vmstat[:buff] = Array.new
    vmstat[:cache] = Array.new
    vmstat[:si] = Array.new
    vmstat[:so] = Array.new
    vmstat[:bi] = Array.new
    vmstat[:bo] = Array.new
    vmstat[:in] = Array.new
    vmstat[:cs] = Array.new
    vmstat[:us] = Array.new
    vmstat[:sy] = Array.new
    vmstat[:id] = Array.new
    vmstat[:wa] = Array.new
    vmstat[:st] = Array.new

vmstat_file = File.open(File.join(opt[:dir], "#{opt[:prefix]}-vmstat")).read
vmstat_file.each_line do |line|
  a = line.split(/\s+/)
  if a[0] != 'procs' && a[0] != 'r' && a[1] != 'r'
    vmstat[:r] << a[0]
    vmstat[:b] << a[1]
    vmstat[:swpd] << a[2]
    vmstat[:free] << a[3]
    vmstat[:buff] << a[4]
    vmstat[:cache] << a[5]
    vmstat[:si] << a[6]
    vmstat[:so] << a[7]
    vmstat[:bi] << a[8]
    vmstat[:bo] << a[9]
    vmstat[:in] << a[10]
    vmstat[:cs] << a[11]
    vmstat[:us] << a[12]
    vmstat[:sy] << a[13]
    vmstat[:id] << a[14]
    vmstat[:wa] << a[15]
    vmstat[:st] << a[16]
  end
end

################################################################################
# Output from diskstats
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Processing diskstats ..."
end

diskstats_i = 0

diskstats_file= File.open(File.join(opt[:dir], "#{opt[:prefix]}-diskstats")).read
diskstats_file.each_line do |line|
  a = line.split(/\s+/)

  if a[0] == 'TS'
    diskstats_i += 1
    diskstats[diskstats_i] = {}
  elsif iostat.keys.include? a[3]
    if !diskstats[diskstats_i].has_key? a[3]
      diskstats[diskstats_i][a[3]] = {}
      diskstats[diskstats_i][a[3]][:reads_issued] = Array.new
      diskstats[diskstats_i][a[3]][:reads_merged] = Array.new
      diskstats[diskstats_i][a[3]][:sectors_read] = Array.new
      diskstats[diskstats_i][a[3]][:time_reading] = Array.new
      diskstats[diskstats_i][a[3]][:writes_completed] = Array.new
      diskstats[diskstats_i][a[3]][:sectors_written] = Array.new
      diskstats[diskstats_i][a[3]][:time_writing] = Array.new
      diskstats[diskstats_i][a[3]][:io_in_progress] = Array.new
      diskstats[diskstats_i][a[3]][:time_io] = Array.new
      diskstats[diskstats_i][a[3]][:weighted_time_io] = Array.new
    else
      diskstats[diskstats_i][a[3]][:reads_issued] = a[4]
      diskstats[diskstats_i][a[3]][:reads_merged] = a[5]
      diskstats[diskstats_i][a[3]][:sectors_read] = a[6]
      diskstats[diskstats_i][a[3]][:time_reading] = a[7]
      diskstats[diskstats_i][a[3]][:writes_completed] = a[8]
      diskstats[diskstats_i][a[3]][:sectors_written] = a[9]
      diskstats[diskstats_i][a[3]][:time_writing] = a[10]
      diskstats[diskstats_i][a[3]][:io_in_progress] = a[11]
      diskstats[diskstats_i][a[3]][:time_io] = a[12]
      diskstats[diskstats_i][a[3]][:weighted_time_io] = a[13]
    end
  end
end

################################################################################
# We have to behave differently based on versions :-(
################################################################################

mysql_version_full=variables['version'].match(/\d+\.\d+\.\d+/).to_s
mysql_version_major=variables['version'].match(/\d+\.\d+/).to_s

################################################################################
# Output from SHOW FULL PROCESSLIST
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Processing pt-stalk processlist ..."
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

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for MySQL Connections ..."
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
  puts "#{`date`.chomp} - Generating .csv file for MySQL Processlist States ..."
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

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for MySQL Query Cache Memory ..."
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
  puts "#{`date`.chomp} - Generating .csv file for Binary Log Cache ..."
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
# Generate the data for Table Definitions
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for Table Definitions ..."
end

table_definitions = true

if mysqladmin["Opened_table_definitions"]
  File.open(File.expand_path("table_definitions.csv", opt[:dest]), "w") do |f|
    f.write "definition_cache,open_table_defs,opened_table_defs\n"

    for i in 1..(mysqladmin["Opened_table_definitions"].length-1)
      f.write variables["table_definition_cache"] + ","
      f.write mysqladmin["Open_table_definitions"][i] + ","
      f.write mysqladmin["Opened_table_definitions"][i] + "\n"
    end
  end
else
  table_definitions = false
end

################################################################################
# Generate the data for Files and Tables
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for Files and Tables ..."
end

tc = "table_open_cache"

if mysql_version_major == '5.0'
  tc = "table_cache"
end

File.open(File.expand_path("files_and_tables.csv", opt[:dest]), "w") do |f|
  f.write "table_cache,open_tables,open_files,opened_tables\n"

  for i in 1..(mysqladmin["Opened_tables"].length-1)
    f.write variables[tc] + ","
    f.write mysqladmin["Open_tables"][i] + ","
    f.write mysqladmin["Open_files"][i] + ","
    f.write mysqladmin["Opened_tables"][i] + "\n"
  end

end

################################################################################
# Generate the data for MyISAM Key Cache
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for MyISAM Key Cache ..."
end

File.open(File.expand_path("myisam_key_cache.csv", opt[:dest]), "w") do |f|
  f.write "key_buffer_size,blocks_used,blocks_not_flushed\n"

  for i in 1..(mysqladmin["Key_blocks_not_flushed"].length-1)
    f.write variables["key_buffer_size"] + ","
    f.write mysqladmin["Key_blocks_used"][i] + ","
    f.write mysqladmin["Key_blocks_not_flushed"][i] + "\n"
  end

end

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

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for Thread Cache ..."
end

File.open(File.expand_path("thread_cache.csv", opt[:dest]), "w") do |f|
  f.write "cache_size,threads_created,threads_cached\n"

  for i in 1..(mysqladmin["Threads_created"].length-1)
    f.write variables["thread_cache_size"] + ","
    f.write mysqladmin["Threads_created"][i] + ","
    f.write mysqladmin["Threads_cached"][i] + "\n"
  end
end

# END MYSQL

################################################################################
# Generate the data for Overall CPU Usage
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for Overall CPU Usage ..."
end

File.open(File.expand_path("overall_cpu_usage.csv", opt[:dest]), "w") do |f|
  f.write "user,nice,sys,iowait,irq,soft,steal,guest,idle\n"

  for i in 1..(mpstat.length-1)
    f.write mpstat[i]["all"][:usr]+ ","
    f.write mpstat[i]["all"][:nice] + ","
    f.write mpstat[i]["all"][:sys] + ","
    f.write mpstat[i]["all"][:iowait] + ","
    f.write mpstat[i]["all"][:irq] + ","
    f.write mpstat[i]["all"][:soft] + ","
    f.write mpstat[i]["all"][:steal] + ","
    f.write mpstat[i]["all"][:guest] + ","
    f.write mpstat[i]["all"][:idle] + "\n"
  end

end

################################################################################
# Generate the data for Per-CPU Non-Idle
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for Per-CPU Non-Idle ..."
end

File.open(File.expand_path("per_cpu_non_idle.csv", opt[:dest]), "w") do |f|

  header=""

  for i in 0..(cores)
    header += "CPU#{i},"
  end

  f.write header[0..-1] + "\n"

  mpstat.keys.sort.each do |k|
    for j in 0..(cores)
      f.write mpstat[k]["#{j}"][:usr].to_f+mpstat[k]["#{j}"][:nice].to_f+mpstat[k]["#{j}"][:sys].to_f+mpstat[k]["#{j}"][:iowait].to_f+mpstat[k]["#{j}"][:irq].to_f+mpstat[k]["#{j}"][:soft].to_f+mpstat[k]["#{j}"][:steal].to_f+mpstat[k]["#{j}"][:guest].to_f
      f.write ","
    end
    f.write "\n"
  end

end

################################################################################
# Generate the data for Per-CPU Graphs
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv files for Per-CPU Graphs ..."
end

# RYAN

################################################################################
# Generate the data for Linux Memory
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for Linux Memory ..."
end

File.open(File.expand_path("linux_memory.csv", opt[:dest]), "w") do |f|
  f.write "Total,Free,Cached,SwapCached\n"

  for i in 1..(meminfo["MemTotal"].length-1)
    f.write meminfo["MemTotal"][i] + ","
    f.write meminfo["MemFree"][i] + ","
    f.write meminfo["Cached"][i] + ","
    f.write meminfo["SwapCached"][i] + "\n"
  end
end

################################################################################
# Generate the data for Disk IO
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv files for Disk IO ..."
end

iostat.keys.each do |disk|
  sanitized_disk = disk.gsub('/','-')
  File.open(File.expand_path("iostat_rw_#{sanitized_disk}.csv", opt[:dest]), "w") do |f|
    f.write "r,w\n"

    for i in 1..(iostat[disk][:r].length-1)
      f.write iostat[disk][:r][i] + ","
      f.write iostat[disk][:w][i] + "\n"
    end
  end

  File.open(File.expand_path("iostat_time_#{sanitized_disk}.csv", opt[:dest]), "w") do |f|
    f.write "queue,service\n"

    for i in 1..(iostat[disk][:svctm].length-1)
      if  iostat[disk][:await][i].to_f >= iostat[disk][:svctm][i].to_f
        f.write iostat[disk][:await][i].to_f - iostat[disk][:svctm][i].to_f
        f.write "," + iostat[disk][:svctm][i] + "\n"
      end
    end
  end
end

################################################################################
# Generate the data for network connection states
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for Network Connection States ..."
end

File.open(File.expand_path("network_connection_states.csv", opt[:dest]), "w") do |f|
  f.write "send_syn,syn_received,established,listen,fin_wait_1,time_wait,close_wait,fin_wait_2,last_ack,closed\n"

  for i in 1..(netstat.length)
    a = {}
    a[:send_syn] = 0
    a[:syn_received] = 0
    a[:established] = 0
    a[:listen] = 0
    a[:fin_wait_1] = 0
    a[:time_wait] = 0
    a[:close_wait] = 0
    a[:fin_wait_2] = 0
    a[:last_ack] = 0
    a[:closed] = 0

    for j in 1..(netstat[i].length)
      if netstat[i][j][:state] == 'SEND_SYN' then a[:send_syn] += 1 end
      if netstat[i][j][:state] == 'SYN_RECEIVED' then a[:syn_received] += 1 end
      if netstat[i][j][:state] == 'ESTABLISHED' then a[:established] += 1 end
      if netstat[i][j][:state] == 'LISTEN' then a[:listen] += 1 end
      if netstat[i][j][:state] == 'FIN_WAIT_1' then a[:fin_wait_1] += 1 end
      if netstat[i][j][:state] == 'TIME_WAIT' then a[:time_wait] += 1 end
      if netstat[i][j][:state] == 'CLOSE_WAIT' then a[:close_wait] += 1 end
      if netstat[i][j][:state] == 'FIN_WAIT_2' then a[:fin_wait_2] += 1 end
      if netstat[i][j][:state] == 'LAST_ACK' then a[:last_ack] += 1 end
      if netstat[i][j][:state] == 'CLOSED' then a[:closed] += 1 end
    end

    f.write a[:send_syn].to_s + ","
    f.write a[:syn_received].to_s + ","
    f.write a[:established].to_s + ","
    f.write a[:listen].to_s + ","
    f.write a[:fin_wait_1].to_s + ","
    f.write a[:time_wait].to_s + ","
    f.write a[:close_wait].to_s + ","
    f.write a[:fin_wait_2].to_s + ","
    f.write a[:last_ack].to_s + ","
    f.write a[:closed].to_s + "\n"
  end
end

################################################################################
# Generate the data for swap
################################################################################

if opt[:debug]
  puts "#{`date`.chomp} - Generating .csv file for swap ..."
end

File.open(File.expand_path("swap.csv", opt[:dest]), "w") do |f|
  f.write "si,so\n"

  for i in 1..(vmstat[:si].length-1)
    f.write vmstat[:si][i] + ","
    f.write vmstat[:so][i] + "\n"
  end
end

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

puts "#{`date`.chomp} - Running overall_cpu_usage.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/overall_cpu_usage.R #{File.expand_path("overall_cpu_usage.csv", opt[:dest])} #{File.expand_path("overall_cpu_usage.png", opt[:dest])}`
puts "#{`date`.chomp} - Running per_cpu_non_idle.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/per_cpu_non_idle.R #{File.expand_path("per_cpu_non_idle.csv", opt[:dest])} #{File.expand_path("per_cpu_non_idle.png", opt[:dest])}`
puts "#{`date`.chomp} - Running linux_memory.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/linux_memory.R #{File.expand_path("linux_memory.csv", opt[:dest])} #{File.expand_path("linux_memory.png", opt[:dest])}`

iostat.keys.each do |disk|
  sanitized_disk = disk.gsub('/','-')
  puts "#{`date`.chomp} - Running iostat_rw.R for #{sanitized_disk}" if opt[:debug]
  `Rscript --no-save #{File.dirname(__FILE__)}/iostat_rw.R #{sanitized_disk} #{File.expand_path("iostat_rw_#{sanitized_disk}.csv", opt[:dest])} #{File.expand_path("iostat_rw_#{sanitized_disk}.png", opt[:dest])}`
  puts "#{`date`.chomp} - Running iostat_time.R for #{sanitized_disk}" if opt[:debug]
  `Rscript --no-save #{File.dirname(__FILE__)}/iostat_time.R #{sanitized_disk} #{File.expand_path("iostat_time_#{sanitized_disk}.csv", opt[:dest])} #{File.expand_path("iostat_time_#{sanitized_disk}.png", opt[:dest])}`
end

puts "#{`date`.chomp} - Running network_connection_states.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/network_connection_states.R #{File.expand_path("network_connection_states.csv", opt[:dest])} #{File.expand_path("network_connection_states.png", opt[:dest])}`

puts "#{`date`.chomp} - Running swap.R" if opt[:debug]
`Rscript --no-save #{File.dirname(__FILE__)}/swap.R #{File.expand_path("swap.csv", opt[:dest])} #{File.expand_path("swap.png", opt[:dest])}`

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

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/overall_cpu_usage.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/per_cpu_non_idle.png' />")
  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/linux_memory.png' />")

  iostat.keys.each do |disk|
    sanitized_disk = disk.gsub('/','-')
    f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/iostat_rw_#{sanitized_disk}.png' />")
    f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/iostat_time_#{sanitized_disk}.png' />")
  end

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/network_connection_states.png' />")

  f.write("<br /><img src='/audit_uploads/#{opt[:prefix]}/swap.png' />")

  f.write("</html>")
end
