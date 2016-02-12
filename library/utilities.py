import re
import xml.etree.ElementTree as etree

from constants import *
from logger import *

RE_CVE_ID = re.compile('CVE-(\d{4})-(\d{4,})')


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

        return details
