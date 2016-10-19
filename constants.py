import os
import re

APP_ROOT_PATH = os.path.normpath(os.path.dirname(os.path.abspath(__file__)))

XMLS_DIRECTORY = os.path.join(APP_ROOT_PATH, 'data/xml')
NVD_XML_URL_TEMPLATE = 'https://nvd.nist.gov/feeds/xml/cve/{filename}'
NVD_GZXML_FILENAME_TEMPLATE = 'nvdcve-2.0-{year}.xml.gz'
NVD_XML_FILENAME_TEMPLATE = 'nvdcve-2.0-{year}.xml'
NVD_CVSS_XML_NAMESPACE = 'http://scap.nist.gov/schema/cvss-v2/0.2'

REPORTS_DIRECTORY = os.path.join(APP_ROOT_PATH, 'data/reports')
HACKERONE_JSON_URL_TEMPLATE = 'https://hackerone.com/reports/{report_id}.json'
HACKERONE_WEB_URL_TEMPLATE = 'https://hackerone.com/reports/{report_id}'
REPORTS_REVIEW_FILEPATH = os.path.join(REPORTS_DIRECTORY, 'reports.review.txt')

ASSETS_DIRECTORY = os.path.join(APP_ROOT_PATH, 'data/assets')
CVES_FILEPATH = os.path.join(ASSETS_DIRECTORY, 'cves.csv')
CVES_REVIEW_FILEPATH = os.path.join(ASSETS_DIRECTORY, 'cves.review.csv')
CVSS_FILEPATH = os.path.join(ASSETS_DIRECTORY, 'cvss.csv')
CVES_RESEARCH_FILEPATH = os.path.join(ASSETS_DIRECTORY, 'cves.research.csv')

RE_CVE_ID = re.compile('CVE-(\d{4})-(\d{4,})')
