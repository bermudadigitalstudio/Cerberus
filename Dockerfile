FROM lgaches/docker-swift:swift-4-dev

WORKDIR /code

COPY Package@swift-4.0.swift /code/Package.swift
COPY ./Sources /code/Sources
COPY ./Tests /code/Tests
RUN swift build

CMD swift test
