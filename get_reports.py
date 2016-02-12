import argparse
import multiprocessing
import os

import requests

from constants import *
from logger import *


def get_reports(min_report_id, max_report_id, num_processes):
    report_ids = list(range(min_report_id, (max_report_id + 1)))

    manager = multiprocessing.Manager()
    sync_queue = manager.Queue(num_processes)

    # Consumer
    process = multiprocessing.Process(
            target=_save, args=(len(report_ids), sync_queue)
        )
    process.start()

    # Producers
    with multiprocessing.Pool(num_processes) as pool:
        pool.starmap(
                get_report,
                [(report_id, sync_queue) for report_id in report_ids]
            )

    process.join()  # Wait until consumer has consumed everything


def get_report(report_id, sync_queue):
    url = HACKERONE_JSON_URL_TEMPLATE.format(report_id=report_id)
    response = requests.get(url, allow_redirects=False)
    debug('HTTP {} for {}'.format(response.status_code, url))
    sync_queue.put(
            (
                report_id,
                response.json() if response.status_code == 200 else None
            ),
            block=True
        )


def _save(count, sync_queue):
    index = 1

    reports = list()
    while index <= count:
        (report_id, response_json) = sync_queue.get(block=True)
        if response_json is not None:
            reports.append((report_id, response_json))

        index += 1

    with_bounty = list()
    with_cve = list()
    if reports:
        for (report_id, report) in reports:
            filename = '{}.json'.format(report_id)
            filepath = os.path.join(REPORTS_DIRECTORY, filename)

            with open(filepath, 'w') as file_:
                file_.write(str(report))
            if report['has_bounty?']:
                with_bounty.append(report_id)
            if report['cve_ids']:
                with_cve.append(report_id)

        info('{}/{} reports publicly accessible.'.format(len(reports), count))
        info('All publicly accessible reports downloaded to {}.'.format(
                REPORTS_DIRECTORY
            ))
        if with_bounty:
            info('{} reports had bounty.'.format(len(with_bounty)))
        else:
            warning('No publicly accesible report had bounty.')

        if with_cve:
            info('{} reports had CVE.'.format(len(with_cve)))
        else:
            warning('No publicly accesible report had CVE.')

        if with_bounty and with_cve:
            bounty_wo_cve = set(with_bounty) - set(with_cve)
            if bounty_wo_cve:
                with open(REPORTS_REVIEW_FILEPATH, 'a') as file_:
                    for report_id in bounty_wo_cve:
                        file_.write('{}\n'.format(
                                HACKERONE_WEB_URL_TEMPLATE.format(
                                    report_id=report_id
                                )
                            ))
                info(
                        (
                            'URL of reports that had bounty without CVE '
                            'written to {}. There were {} such reports.'
                        ).format(REPORTS_REVIEW_FILEPATH,  len(bounty_wo_cve))
                    )
    else:
        warning('No reports in the range specified were publicly accessible.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            description=(
                'Script to query potential security vulnerability reports'
                ' on hackerone.com looking for the ones that are publicly'
                ' accessible.'
            )
        )
    parser.add_argument(
            '-n', '--num-processes', type=int, dest='num_processes', default=4,
            help=(
                'Number of processes to spawn when querying reports in'
                ' parallel. Default is 4.'
            )
        )
    parser.add_argument(
            'min_report_id', type=int,
            help='Minimum value of the report identifier to query.'
        )
    parser.add_argument(
            'max_report_id', type=int,
            help='Maximum value of the report identifier to query.'
        )
    args = parser.parse_args()

    if not os.path.exists(REPORTS_DIRECTORY):
        debug('Directory \'{}\' created.'.format(REPORTS_DIRECTORY))
        os.mkdir(REPORTS_DIRECTORY)

    get_reports(
            abs(args.min_report_id),
            abs(args.max_report_id),
            args.num_processes
        )
