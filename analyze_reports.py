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

    missing_cve = 0
    missing_nvd = 0
    reports = dict()
    for report_id in report_ids:
        filepath = os.path.join(REPORTS_DIRECTORY, '{}.json'.format(report_id))
        debug(filepath)
        report = analyze_report(filepath)
        if report['hackerone']['bounty'] is not None:
            if report['nvd'] is None:
                missing_cve += 1
            elif len(report['nvd']) == 0:
                missing_nvd += 1
            else:
                reports[report_id] = report

    warning('{} reports with bounty did not have a CVE.'.format(missing_cve))
    warning('{} reports had CVE not found in NVD.'.format(missing_nvd))

    cves = list()
    cvsses = list()
    metrics = None
    for (report_id, report) in reports.items():
        bounty = (
                report['hackerone']['bounty'] /
                len(report['hackerone']['cve_ids'])
            )
        for (cve_id, cvss) in report['nvd'].items():
            cves.append(
                    (
                        cve_id, report['hackerone']['product'], bounty,
                        HACKERONE_WEB_URL_TEMPLATE.format(
                            report_id=report_id
                        )
                    )
                )
            cvss = sorted(cvss.items(), key=operator.itemgetter(0))
            cvsses.append((cve_id, ) + tuple(v for (_, v) in cvss))
            if not metrics:
                metrics = [i for (i, _) in cvss]

    if is_output_enabled:
        with open(CVES_FILEPATH, 'w') as file_:
            writer = csv.writer(file_)
            writer.writerows(sorted(cves, key=lambda t: t[1]))
        info('CVEs written to {}'.format(CVES_FILEPATH))
        with open(CVSS_FILEPATH, 'w') as file_:
            writer = csv.writer(file_)
            writer.writerows(sorted(cvsses, key=lambda t: t[0]))
        info('CVSSs written to {}'.format(CVSS_FILEPATH))
    else:
        for (index, cve) in enumerate(cves):
            info('[#{:3d}] {} ${:,.2f}'.format(
                    (index + 1), cve[1], cve[2],
                ))
            for cvss in cvsses:
                if cvss[0] == cve[0]:
                    info('  {}'.format(cve[0]))
                    for (metric, value) in zip(metrics, cvss[1:]):
                        info('    {:25} {}'.format(metric, value))


def analyze_report(filepath):
    details = {'hackerone': None, 'nvd': None}
    with open(filepath, 'r') as file_:
        details['hackerone'] = utilities.Report.get_details(json.load(file_))

    if details['hackerone']['cve_ids']:
        details['nvd'] = dict()
        for cve_id in details['hackerone']['cve_ids']:
            nvd_details = nvdxml.get_details(cve_id)
            if nvd_details:
                details['nvd'][cve_id] = nvd_details

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
