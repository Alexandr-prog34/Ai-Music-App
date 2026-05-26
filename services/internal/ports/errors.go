package ports

import "errors"

var ErrMessageMovedToDLQ = errors.New("message moved to dlq")
