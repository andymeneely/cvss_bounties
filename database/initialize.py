import argparse

import sqlalchemy

import settings
from models import *


def initialize(environment):
    engine = sqlalchemy.engine_from_config(settings.settings[environment])
    Base.metadata.create_all(engine)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Intialize the database.')
    parser.add_argument(
            'environment', help='Database environment to initialize.',
            choices=['DEVELOPMENT', 'PRODUCTION']
        )
    args = parser.parse_args()
    initialize(args.environment)
