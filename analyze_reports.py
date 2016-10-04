import argparse
import csv
import json
import operator
import os
import sys

from constants import *
from library import utilities
from logger import *

nvdxml = utilities.NvdXml()


def analyze_reports(is_output_enabled=False):
    report_ids = [
            filename.replace('.json', '')
            for filename in os.listdir(REPORTS_DIRECTORY)
            if 'json' in filename
        ]

    if not report_ids:
        warning(
                'No reports to analyze in {}. Run get_reports.py.'.format(
                    REPORTS_DIRECTORY
                )
            )
        sys.exit(0)

    missing_bounty = 0
    missing_cve = 0
    reports = dict()
    for report_id in report_ids:
        filepath = os.path.join(REPORTS_DIRECTORY, '{}.json'.format(report_id))
        debug(filepath)
        report = analyze_report(filepath)
        if report['hackerone']['bounty'] is not None:
            if report['has_cve']:
                reports[report_id] = report
            else:
                missing_cve += 1
        else:
            missing_bounty += 1

    warning('{} reports did not have a bounty.'.format(missing_bounty))
    warning('{} reports with bounty did not have a CVE.'.format(missing_cve))

    cves = list()
    cvsses = list()
    metrics = None
    for (report_id, report) in reports.items():
        bounty = (
                report['hackerone']['bounty'] /
                len(report['hackerone']['cve_ids'])
            )
        for cve_id in report['hackerone']['cve_ids']:
            cves.append(
                    (
                        cve_id, report['hackerone']['product'], bounty,
                        HACKERONE_WEB_URL_TEMPLATE.format(
                            report_id=report_id
                        )
                    )
                )

    if is_output_enabled:
        with open(CVES_FILEPATH, 'w') as file_:
            writer = csv.writer(file_)
            writer.writerows(sorted(cves, key=lambda t: t[1]))
        info('CVEs written to {}'.format(CVES_FILEPATH))
    else:
        for (index, cve) in enumerate(cves):
            info('#{:3d} {} {} ${:,.2f}'.format(
                    (index + 1), cve[0], cve[1], cve[2],
                ))


def analyze_report(filepath):
    details = {'hackerone': None, 'has_cve': None}
    with open(filepath, 'r') as file_:
        details['hackerone'] = utilities.Report.get_details(json.load(file_))
        details['has_cve'] = True if details['hackerone']['cve_ids'] else False

    return details


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            description=(
                'Script to analyze publicly accesible reports downloaded from '
                'hackerone.com.'
            )
        )
    parser.add_argument(
            '-o', '--output', dest='output', action='store_true',
            help='Generate output files instead of using standard output.'
        )
    args = parser.parse_args()
    analyze_reports(args.output)
