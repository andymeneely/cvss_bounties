from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()


class Cve(Base):
    __tablename__ = 'cve'

    id = Column(String, primary_key=True)
    product = Column(String, nullable=False)

    # Navigation
    cvss = relationship('Cvss', uselist=False, back_populates='cve')
    bounty = relationship('Bounty', uselist=False, back_populates='cve')

    def __repr__(self):
        return self.cve_id


class Cvss(Base):
    __tablename__ = 'cvss'

    id = Column(Integer, primary_key=True)
    cve_id = Column(String, ForeignKey('cve.id'))

    base_score = Column(Integer, nullable=False)
    vector = Column(String, nullable=False)

    # Navigation
    cve = relationship('Cve', back_populates='cvss')


class Bounty(Base):
    __tablename__ = 'bounty'

    id = Column(Integer, primary_key=True)
    cve_id = Column(String, ForeignKey('cve.id'))

    amount = Column(Integer, nullable=False)
    awarded_to = Column(String, nullable=True)

    # Navigation
    cve = relationship('Cve', back_populates='bounty')
