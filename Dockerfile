FROM golang:1.19.1 AS builder
WORKDIR /go/src/app
COPY . .
RUN go build -o /go/bin/app

FROM gcr.io/distroless/base-debian10
COPY --from=builder /go/bin/app /app
ENTRYPOINT ["/app"]
