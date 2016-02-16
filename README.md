# CVSS vs. Bounties

A collection of scripts written for the CVSS vs. Bounties project.

# Installation

1. Create a virtual environment using `virtualenv --python=python3 venv`
1. Activate the virtual environment using `source venv/bin/activate`
1. Install the dependencies `pip install -r requirements.txt`

# HackerOne Report Download

```
usage: get_reports.py [-h] [-n NUM_PROCESSES] min_report_id max_report_id

Script to query potential security vulnerability reports on hackerone.com
looking for the ones that are publicly accessible.

positional arguments:
  min_report_id         Minimum value of the report identifier to query.
  max_report_id         Maximum value of the report identifier to query.

optional arguments:
  -h, --help            show this help message and exit
  -n NUM_PROCESSES, --num-processes NUM_PROCESSES
                        Number of processes to spawn when querying reports in
                        parallel. Default is 4.
```

# NVD XML Feed Download

```
usage: get_nvd_xmls.py [-h] [-y YEAR]

Script to download NVD XML feed files.

optional arguments:
  -h, --help            show this help message and exit
  -y YEAR, --year YEAR  Download the XML feed for a specified year. Default is
                        None, where all XML feed files starting at year 2002
                        to the present year are downloaded.
```

# Analyze HackerOne Reports

```
usage: analyze_reports.py [-h] [-o]

Script to analyze publicly accesible reports downloaded from hackerone.com.

optional arguments:
  -h, --help    show this help message and exit
  -o, --output  Generate output files instead of using standard output.
```

# Initialize Database

The `database.initialize` module creates all the models. The settings used are
in the `database.settings` module.

```
usage: initialize.py [-h] {DEVELOPMENT,PRODUCTION}

Intialize the database.

positional arguments:
  {DEVELOPMENT,PRODUCTION}
                        Database environment to initialize.

optional arguments:
  -h, --help            show this help message and exit
```

# Load Database

The `load_database` module loads bounty data from a CSV file into a database in
the environment identified by the `DEFAULT` setting in the `database.settings`
module.

```
usage: load_database.py [-h] file

Load the database with bounty from a CSV file.

positional arguments:
  file        Path to the file containing bounty. The file must be in CSV
              format with a header. The first three columns of the file must
              contain CVE, the name of the product, and bounty amount, in that
              order.

optional arguments:
  -h, --help  show this help message and exit
```
