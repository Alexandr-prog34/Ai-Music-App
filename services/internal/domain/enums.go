package domain

// SunoModel — перечисление моделей из вашего OpenAPI контракта.
type SunoModel string

const (
	SunoModelV4      SunoModel = "V4"
	SunoModelV45     SunoModel = "V4_5"
	SunoModelV45Plus SunoModel = "V4_5PLUS"
	SunoModelV45All  SunoModel = "V4_5ALL"
	SunoModelV5      SunoModel = "V5"
)

// VocalGender — голос (если трек с вокалом).
type VocalGender string

const (
	VocalMale   VocalGender = "m"
	VocalFemale VocalGender = "f"
)

// JobStatus — статусы job из OpenAPI контракта.
type JobStatus string

const (
	JobQueued     JobStatus = "queued"
	JobProcessing JobStatus = "processing"
	JobReady      JobStatus = "ready"
	JobFailed     JobStatus = "failed"
)
