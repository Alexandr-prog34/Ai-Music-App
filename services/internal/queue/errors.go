package queue

import "errors"

var (
	// ErrJobIDEmpty — пустой jobID передали в очередь
	ErrJobIDEmpty = errors.New("jobID is empty")

	// ErrUnexpectedBRPopResult — Redis BRPOP вернул неожиданный формат
	ErrUnexpectedBRPopResult = errors.New("unexpected BRPOP result")
)