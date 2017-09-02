FROM swift:3.1

WORKDIR /code

COPY Package.swift Package.pins /code/
RUN swift build || true

COPY ./Sources /code/Sources
COPY ./Tests /code/Tests
RUN mv ./Tests/IntegrationTests /code/Sources/TestIntegration
RUN swift build
CMD .build/debug/TestIntegration
