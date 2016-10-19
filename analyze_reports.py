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


def analyze_reports(is_output_enabled):
    report_ids = [
            filename.replace('.json', '')
            for filename in os.listdir(REPORTS_DIRECTORY)
            if 'json' in filename
        ]

    if not report_ids:
        message = 'No reports to analyze in {}. Run get_reports.py.'. \
            format(REPORTS_DIRECTORY)
        error(message)
        sys.exit(-1)

    reports = dict()  # Reports that have bounty and CVE
    unearthed = dict()  # ... bounty but CVE had to be unearthed from report
    research = dict()  # ... bounty but no CVE
    for report_id in report_ids:
        filepath = os.path.join(REPORTS_DIRECTORY, '{}.json'.format(report_id))
        debug(filepath)

        (report, has_cve) = analyze_report(filepath)
        if report['bounty'] is not None:
            if has_cve:
                if report['unearthed'] is True:
                    unearthed[report_id] = report
                else:
                    reports[report_id] = report
            else:
                research[report_id] = report

    count = len(reports) + len(unearthed)
    info('{}/{} reports have bounty'.format(count, len(report_ids)))
    warning('{} reports already had CVE'.format(len(reports)))
    warning('{} reports needed CVE to be unearthed'.format(len(unearthed)))
    warning('{} reports with bounty have no CVE'.format(len(research)))

    ordered_reports = sorted(_format(reports), key=lambda t: t[1])
    ordered_unearthed = sorted(_format(unearthed), key=lambda t: t[1])
    ordered_research = sorted(_format(research), key=lambda t: t[1])
    if is_output_enabled:
        with open(CVES_FILEPATH, 'w') as file_:
            writer = csv.writer(file_)
            writer.writerows(ordered_reports)
        info('CVEs written to {}'.format(CVES_FILEPATH))

        with open(CVES_REVIEW_FILEPATH, 'w') as file_:
            writer = csv.writer(file_)
            writer.writerows(ordered_unearthed)
        info('{} has CVEs needing review'.format(CVES_REVIEW_FILEPATH))

        with open(CVES_RESEARCH_FILEPATH, 'w') as file_:
            writer = csv.writer(file_)
            writer.writerows(ordered_research)
        info('{} has CVEs needing research'.format(CVES_RESEARCH_FILEPATH))
    else:
        for (index, item) in enumerate(ordered_reports):
            info('#{:3d} {} {} ${:,.2f}'.format(
                    (index + 1), item[0], item[1], item[2],
                ))
        for (index, item) in enumerate(ordered_unearthed):
            info('#{:3d} {} {} ${:,.2f}*'.format(
                    (index + 1), item[0], item[1], item[2],
                ))
        for (index, item) in enumerate(ordered_research):
            info('#{:3d} {} {} ${:,.2f}+'.format(
                    (index + 1), item[0], item[1], item[2],
                ))
        info('* Review for accuracy  + Research to identify CVE')


def analyze_report(filepath):
    (details, has_cve) = (None, None)

    with open(filepath, 'r') as file_:
        details = utilities.Report.get_details(json.load(file_))
        has_cve = True if details['cve_ids'] else False

    return (details, has_cve)


def _format(reports):
    formatted = list()

    for (report_id, report) in reports.items():
        if len(report['cve_ids']) > 0:
            bounty = report['bounty'] / len(report['cve_ids'])
            for cve_id in report['cve_ids']:
                formatted.append(
                        (
                            cve_id, report['product'], bounty,
                            HACKERONE_WEB_URL_TEMPLATE.format(
                                report_id=report_id
                            )
                        )
                    )
        else:
            formatted.append(
                    (
                        '-', report['product'], report['bounty'],
                        HACKERONE_WEB_URL_TEMPLATE.format(
                            report_id=report_id
                        )
                    )
                )

    return formatted


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
