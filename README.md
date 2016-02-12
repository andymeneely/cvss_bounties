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
