FROM golang:1.24-alpine

WORKDIR /app

COPY services/go.* ./
RUN go mod download

COPY services .

RUN go build -o worker ./cmd/worker

CMD ["./worker"]
