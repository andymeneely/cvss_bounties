import argparse
import csv

import sqlalchemy

from database import Session
from database.models import *
from logger import *
from library import utilities


def load(file_):
    nvdxml = utilities.NvdXml()
    session = Session()

    reader = csv.reader(file_)
    next(reader, None)   # Ignoring the header
    for row in reader:
        debug(row)
        cve = Cve(id=row[0], product=row[1])
        nvd_details = nvdxml.get_details(cve.id)

        if nvd_details:
            cve.cvss = Cvss()

            cve.cvss.access_complexity = nvd_details['access-complexity']
            cve.cvss.access_vector = nvd_details['access-vector']
            cve.cvss.authentication = nvd_details['authentication']
            cve.cvss.availability_impact = nvd_details['availability-impact']
            cve.cvss.confidentiality_impact = nvd_details[
                    'confidentiality-impact'
                ]
            cve.cvss.integrity_impact = nvd_details['integrity-impact']
            cve.cvss.score = nvd_details['score']
            cve.cvss.exploitability_subscore = nvd_details[
                    'exploitability-subscore'
                ]
            cve.cvss.impact_subscore = nvd_details[
                    'impact-subscore'
                ]

            cve.bounty = Bounty()

            cve.bounty.amount = float(row[2].replace('$', '').replace(',', ''))

            session.add(cve)
            try:
                session.commit()
            except sqlalchemy.exc.IntegrityError as e:
                error('{} is a duplicate.'.format(cve.id))
                session.rollback()
        else:
            warning('{} was not found in NVD.'.format(cve.id))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            description='Load the database with bounty from a CSV file.'
        )
    parser.add_argument(
            'file', type=argparse.FileType('r'),
            help=(
                'Path to the file containing bounty. The file must be in CSV '
                ' format with a header. The first three columns of the file '
                ' must contain CVE, the name of the product, and bounty '
                ' amount, in that order.'
            )
        )
    args = parser.parse_args()
    load(args.file)
