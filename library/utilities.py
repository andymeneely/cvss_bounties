import json
import os
import re
import xml.etree.ElementTree as etree

from constants import *
from logger import *

RE_CVE_ID = re.compile('CVE-(\d{4})-(\d{4,})')
AV_LOOKUP = {'local': 0.395, 'adjacent_network': 0.646, 'network': 1.0}
AC_LOOKUP = {'low': 0.71, 'medium': 0.61, 'high': 0.35}
AU_LOOKUP = {
        'none': 0.704, 'single_instance': 0.56, 'multiple_instances': 0.45
    }
IMPACT_LOOKUP = {'none': 0.0, 'partial': 0.275, 'complete': 0.660}


class NvdXml(object):
    def __init__(self):
        self._xmls = dict()

    def get_details(self, cve_id):
        details = None

        match = RE_CVE_ID.search(cve_id)
        if not match:
            raise Exception('Invalid CVE ID {}.'.format(cve_id))

        year = match.group(1)
        if year not in self._xmls:
            filepath = os.path.join(
                    XMLS_DIRECTORY,
                    NVD_XML_FILENAME_TEMPLATE.format(year=year)
                )
            if not os.path.exists(filepath):
                raise Exception('Missing NVD XML file {}.'.format(filepath))
            self._xmls[year] = etree.parse(filepath)
            debug('{} cached'.format(filepath))

        element = self._xmls[year].find(
                '.*[@id=\'{}\']//cvss:base_metrics'.format(cve_id),
                namespaces={'cvss': NVD_CVSS_XML_NAMESPACE}
            )
        if element:
            details = dict()
            for child in element.getchildren():
                tagname = child.tag.replace(
                        '{{{}}}'.format(NVD_CVSS_XML_NAMESPACE), ''
                    )
                details[tagname] = child.text
            details['exploitability-subscore'] = (
                    self._get_exploitability_subscore(
                            details['access-complexity'],
                            details['access-vector'],
                            details['authentication']
                        )
                )
            details['impact-subscore'] = (
                    self._get_impact_subscore(
                            details['availability-impact'],
                            details['confidentiality-impact'],
                            details['integrity-impact']
                        )
                )

        return details

    def _get_exploitability_subscore(self, ac, av, au):
        exploitability_subscore = (
                20 *
                AV_LOOKUP[av.lower()] *
                AC_LOOKUP[ac.lower()] *
                AU_LOOKUP[au.lower()]
            )
        return round(exploitability_subscore, 1)

    def _get_impact_subscore(self, ai, ci, ii):
        impact_subscore = (
                10.41 *
                (
                    1 -
                    (1 - IMPACT_LOOKUP[ai.lower()]) *
                    (1 - IMPACT_LOOKUP[ci.lower()]) *
                    (1 - IMPACT_LOOKUP[ii.lower()])
                )
            )
        return round(impact_subscore, 1)


class Report(object):
    @staticmethod
    def get_details(report):
        bounty = None
        if report['has_bounty?']:
            if 'bounty_amount' in report:
                bounty = float(report['bounty_amount'])
            else:
                for activity in report['activities']:
                    if 'bounty_amount' in activity:
                        bounty = float(
                                activity['bounty_amount'].replace(',', '')
                            )
                        break
        cves = None
        if report['cve_ids']:
            cves = report['cve_ids']
        product = report['team']['name']

        return {'product': product, 'cve_ids': cves, 'bounty': bounty}
