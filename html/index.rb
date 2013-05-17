<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
    <title>Percona - Generate Performance Audit Graphs</title>
  
    <style type="text/css">
html,body {
    padding-left: 0;
    padding-right: 0;
    margin-left: auto;
    margin-right: auto;
    display: block;
    width: 800px;
}
    </style>
  </head>

<body>

<h1>Generate Graphs for a Percona Health Audit</h1>

  <p>At least one metric capture is required</p>

  <form method="post" enctype="multipart/form-data" action="/percona/uploader.rb">

    <table>
      <tr>
        <td>*</td>
        <td>Issue Number:</td>
        <td><input type="text" name="issue_number" size="10"/></td>
      </tr>
      <tr>
        <td></td>
        <td>pt-stalk File (tar, tgz, tar.gz):</td>
        <td><input type="file" name="pt_stalk" size="10"/></td>
      </tr>
      <tr>
        <td></td>
        <td>mpstat File (Plain Text, gz):</td>
        <td><input type="file" name="mpstat" size="10"/></td>
      </tr>
      <tr>
        <td></td>
        <td>vmstat File (Plain Text, gz):</td>
        <td><input type="file" name="vmstat" size="10"/></td>
      </tr>
      <tr>
        <td></td>
        <td>mysqladmin File (Plain Text, gz):</td>
        <td><input type="file" name="mysqladmin" size="10"/></td>
      </tr>
      <tr>
        <td></td>
        <td>pt-mext File (Plain Text, gz):</td>
        <td><input type="file" name="pt_mext" size="10"/></td>
      </tr>
      <tr>
        <td></td>
        <td>myq_gadgets File (tar, tgz, tar.gz):</td>
        <td><input type="file" name="myq_gadgets" size="10"/></td>
      </tr>
      <tr>
        <td></td>
        <td></td>
        <td align="right"><input type="submit" value="Generate Graphs" /></td>
      </tr>
    </table>

  </form>

  <br /><br />
  <p>This graph generation tool assumes that the commands have been invoked as follows:</p>
  <br />

  <pre>
    $ pt-stalk --no-stalk --run-time=1200
    $ mpstat -P ALL 60 60 > mpstat.out 
    $ vmstat 60 60 > vmstat.out 
    $ mysqladmin ext -r -i 60 -c 60 > mysqladmin.out 
    $ pt-diskstats --interval 60 --group-by all --iterations 60 --show-timestamps --show-inactive > pt-diskstats.out
  </pre>

  <br />
  <p>This project currently lives at <a href="github.com/rlowe/stalk2graph">github.com/rlowe/stalk2graph</a></p>
  <br /><br />

</body>

</html>
