import sqlalchemy
from sqlalchemy.orm import sessionmaker

from database import settings

engine = sqlalchemy.engine_from_config(
        settings.settings[settings.settings['DEFAULT']]
    )
Session = sessionmaker(bind=engine)
