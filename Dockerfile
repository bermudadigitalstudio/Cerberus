FROM swift:3.1

WORKDIR /code

COPY Package.swift.test /code/Package.swift
COPY Package.pins /code/Package.pins
RUN swift build || true

COPY ./Sources /code/Sources
COPY ./Tests /code/Tests
RUN mv ./Tests/CerberusIntegrationTests /code/Sources/TestIntegration
RUN swift build
CMD .build/debug/TestIntegration
