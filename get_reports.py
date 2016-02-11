import argparse
import multiprocessing
import os

import requests

from logger import *

JSON_URL_TEMPLATE = 'https://hackerone.com/reports/{report_id}.json'
WEB_URL_TEMPLATE = 'https://hackerone.com/reports/{report_id}'
REPORTS_DIRECTORY = 'reports'
REPORT_FILENAME_TEMPLATE = REPORTS_DIRECTORY + '/{report_id}.json'
WITH_BOUNTY_FILENAME = 'with_bounties.txt'
WITH_CVE_FILENAME = 'with_cve.txt'


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
    url = JSON_URL_TEMPLATE.format(report_id=report_id)
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
            if report:
                filename = REPORT_FILENAME_TEMPLATE.format(report_id=report_id)
                with open(filename, 'w') as file_:
                    file_.write(str(report))
                    info('{} written.'.format(filename))
                if report['has_bounty?']:
                    with_bounty.append(report_id)
                if report['cve_ids']:
                    with_cve.append(report_id)

        if with_bounty:
            info('{} reports had bounty.'.format(len(with_bounty)))
            with open(WITH_BOUNTY_FILENAME, 'a') as file_:
                for report_id in with_bounty:
                    file_.write('{}\n'.format(
                            WEB_URL_TEMPLATE.format(report_id=report_id)
                        ))
            info('URL of reports with bounty written to {}.'.format(
                    WITH_BOUNTY_FILENAME
                ))
        else:
            warning('None of the publicly accesible reports had bounty.')

        if with_cve:
            info('{} reports had CVE.'.format(len(with_cve)))
            with open(WITH_CVE_FILENAME, 'a') as file_:
                for report_id in with_cve:
                    file_.write('{}\n'.format(
                            WEB_URL_TEMPLATE.format(report_id=report_id)
                        ))
            info('URL of reports with CVE written to {}.'.format(
                    WITH_CVE_FILENAME
                ))
        else:
            warning('None of the publicly accesible reports had CVE.')
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
