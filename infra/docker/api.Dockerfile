FROM golang:1.22-alpine

WORKDIR /app

COPY services/go.* ./
RUN go mod download

COPY services .

RUN go build -o api ./cmd/api

EXPOSE 8080
CMD ["./api"]
