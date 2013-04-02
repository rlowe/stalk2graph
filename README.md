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
    $ brew install R
    $ sudo gem install json

    R> install.packages('ggplot2')

TO DO
=====

* Ordering is important for graph line addition.  Update each R script
  to always explicitly graph the one with max() first.  See
  innodb_buffer_pool.R for prior art.
* (via jay) I do still want the ability to upload individual files (like say a mysqladmin style file) and get the releated graphs without needing to pretend it's a whole pt-stalk output.
* Integrate Kenny's stuff

http://www.percona.com/doc/percona-monitoring-plugins/cacti/unix-templates.html

NOTES
=====

* https://gist.github.com/rlowe/01d628a034156bcca62d

INSTALLATION INSTRUCTIONS
=========================

1) Install and Configure R, Ruby, mod_ruby, and apache2
2) Check out the repository into the target repository (usually
http://<blah>/stalk2graph/
