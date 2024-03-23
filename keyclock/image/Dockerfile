ARG KEYCLOACK_VERSION=24.0.1


FROM lzocateli/keyclock:$KEYCLOACK_VERSION as builder


ARG KEYCLOACK_VERSION=24.0.1
ARG DB_VENDOR=mssql

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=false
ENV KC_DB=$DB_VENDOR


WORKDIR /opt/keycloak
# for demonstration purposes only, please make sure to use proper certificates in production instead
RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" -keystore conf/server.keystore
RUN /opt/keycloak/bin/kc.sh build

FROM lzocateli/keyclock:$KEYCLOACK_VERSION
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ARG DB_VENDOR=mssql

ENV KC_DB=$DB_VENDOR
ENV KC_DB_URL=<DBURL>
ENV KC_DB_USERNAME=<DBUSERNAME>
ENV KC_DB_PASSWORD=<DBPASSWORD>
ENV KC_HOSTNAME=localhost
#ENV KC_TRUSTSTORE_PATHS=/opt/truststore/myTrustStore.pfx,/opt/other-truststore/myOtherTrustStore.pem

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]