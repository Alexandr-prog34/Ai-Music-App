package queue

import "errors"

var (
	// ErrJobIDEmpty — пустой jobID передали в очередь
	ErrJobIDEmpty = errors.New("jobID is empty")
	ErrQueuePayloadEmpty = errors.New("queue payload is empty")
	ErrQueueAckFailed = errors.New("queue ack failed")

	// ErrUnexpectedBRPopResult — Redis BRPOP вернул неожиданный формат
	ErrUnexpectedBRPopResult = errors.New("unexpected BRPOP result")
)
