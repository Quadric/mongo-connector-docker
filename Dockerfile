FROM quadric/mongo-connector:2.5-es_2.4.1

LABEL net.quadric.vendor="Quadric ApS" maintainer="Ahmed Magdy <ahmed.magdy@quadric.net>"

RUN pip install neo4j-doc-manager==0.1.2