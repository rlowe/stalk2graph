stalk2graph
===========

Convert the output of pt-stalk to graphs

pt-stalk Usage
--------------

# Gotta have the latest version (2.1.2+)
$ wget percona.com/get/pt-stalk

# --run-time=1200 to get an hour of data. 
# You can use any runtime, but graphs look 
# really chunky with < 100 observations
$ ./pt-stalk --no-stalk --run-time=1200

Directory Structure
-------------------
bin/ <- Contains the master stalk2graph.rb and individual R files for each graph

Environmental Setup
-------------------

### On a mac :-D

$ brew install gfortran
$ brew install R # Note this may require additional dependencies depending on OS X version

R> install.packages('ggplot2')

TO DO
=====

* Each graph on http://www.percona.com/doc/percona-monitoring-plugins/cacti/mysql-templates.html

NOTES
=====

* https://gist.github.com/rlowe/01d628a034156bcca62d
