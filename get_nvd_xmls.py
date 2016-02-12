import argparse
import gzip
import os

from datetime import datetime

import requests

from constants import *
from logger import *


def get_nvd_xmls(years):
    for year in years:
        gz_filename = NVD_GZXML_FILENAME_TEMPLATE.format(year=year)
        xml_filename = NVD_XML_FILENAME_TEMPLATE.format(year=year)
        url = NVD_XML_URL_TEMPLATE.format(filename=gz_filename)

        response = requests.get(url)
        debug('HTTP {} for {}'.format(response.status_code, url))
        if response.status_code == 200:
            gz_filepath = os.path.join(XMLS_DIRECTORY, gz_filename)
            xml_filepath = os.path.join(XMLS_DIRECTORY, xml_filename)

            with open(gz_filepath, 'wb') as file_:
                for chunk in response.iter_content(1024):
                    file_.write(chunk)
            debug('{} downloaded to {}'.format(gz_filename, gz_filepath))

            with gzip.open(gz_filepath) as gz_file:
                with open(xml_filepath, 'wb') as xml_file:
                    xml_file.write(gz_file.read())
            debug('{} extracted to {}'.format(gz_filename, xml_filepath))
            os.remove(gz_filepath)
            debug('{} deleted'.format(gz_filepath))
            info('Downloaded {}'.format(xml_filename))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            description='Script to download NVD XML feed files.'
        )
    parser.add_argument(
            '-y', '--year', type=int, dest='year', default=None,
            help=(
                'Download the XML feed for a specified year. Default is None, '
                'where all XML feed files starting at year 2002 to the '
                'present year are downloaded.'
            )
        )
    args = parser.parse_args()

    years = None
    if args.year is not None:
        years = [args.year]
    else:
        years = [year for year in range(2002, (datetime.today().year + 1))]

    get_nvd_xmls(years)
