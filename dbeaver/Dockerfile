ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM dbeaver/cloudbeaver:26.1.3

ARG DRIVER_VERSION=3.14.5

WORKDIR /opt/cloudbeaver

ADD https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/$DRIVER_VERSION/snowflake-jdbc-$DRIVER_VERSION.jar /opt/cloudbeaver/drivers/
RUN chmod 644 /opt/cloudbeaver/drivers/snowflake-jdbc-$DRIVER_VERSION.jar

EXPOSE 8978
