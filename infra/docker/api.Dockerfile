FROM golang:1.24-alpine

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY services/go.* ./
RUN go mod download

COPY services .
RUN go mod download

RUN go build -o api ./cmd/api

EXPOSE 8080
CMD ["./api"]
