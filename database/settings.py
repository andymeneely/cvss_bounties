import sqlalchemy.engine.url

settings = {
    'DEFAULT': 'DEVELOPMENT',
    'TEST': {
        'sqlalchemy.url': sqlalchemy.engine.url.URL(
            drivername='sqlite',
            username=None,
            password=None,
            host=None,
            port=None,
            database=None
        )
    },
    'DEVELOPMENT': {
        'sqlalchemy.url': sqlalchemy.engine.url.URL(
            drivername='sqlite',
            username=None,
            password=None,
            host=None,
            port=None,
            database='db.sqlite3'
        )
    },
    'PRODUCTION': {
        'sqlalchemy.url': sqlalchemy.engine.url.URL(
            drivername='postgresql',
            username=None,
            password=None,
            host='localhost',
            port='5432',
            database='bountyvscvss'
        )
    }
}
