from sqlalchemy import Column, Integer, String, Float, ForeignKey
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
        return self.id


class Cvss(Base):
    __tablename__ = 'cvss'

    id = Column(Integer, primary_key=True)
    cve_id = Column(String, ForeignKey('cve.id'), nullable=False)

    access_complexity = Column(String, nullable=False)
    access_vector = Column(String, nullable=False)
    authentication = Column(String, nullable=False)
    availability_impact = Column(String, nullable=False)
    confidentiality_impact = Column(String, nullable=False)
    integrity_impact = Column(String, nullable=False)
    score = Column(Float, nullable=False)

    # Navigation
    cve = relationship('Cve', back_populates='cvss')


class Bounty(Base):
    __tablename__ = 'bounty'

    id = Column(Integer, primary_key=True)
    cve_id = Column(String, ForeignKey('cve.id'), nullable=False)

    amount = Column(Float, nullable=False)

    # Navigation
    cve = relationship('Cve', back_populates='bounty')
