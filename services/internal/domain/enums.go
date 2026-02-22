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

func (s SunoModel) String() string { return string(s) }

func (m SunoModel) isValid() bool {
	switch m {
	case SunoModelV4, SunoModelV45, SunoModelV45Plus, SunoModelV45All, SunoModelV5:
		return true
	default:
		return false
	}
}

func (m SunoModel) Validate() error {
	if m == "" {
		return InvalidInput(ErrModelRequired)
	}
	if !m.isValid() {
		return InvalidInput(ErrModelInvalid, "got=%q", m.String())
	}
	return nil
}

// VocalGender — голос (если трек с вокалом).
type VocalGender string

const (
	VocalMale   VocalGender = "m"
	VocalFemale VocalGender = "f"
)

func (s VocalGender) String() string { return string(s) }

func (v VocalGender) isValid() bool {
	switch v {
	case VocalMale, VocalFemale:
		return true
	default:
		return false
	}
}

func (g VocalGender) Validate() error {
	if g == "" {
		return InvalidInput(ErrVocalGenderRequired)
	}
	if !g.isValid() {
		return InvalidInput(ErrVocalGenderInvalid, "got=%q", g.String())
	}
	return nil
}

// JobStatus — статусы job из OpenAPI контракта.
type JobStatus string

const (
	JobQueued     JobStatus = "queued"
	JobProcessing JobStatus = "processing"
	JobReady      JobStatus = "ready"
	JobFailed     JobStatus = "failed"
)

func (s JobStatus) String() string { return string(s) }

func (s JobStatus) isValid() bool {
	switch s {
	case JobQueued, JobProcessing, JobReady, JobFailed:
		return true
	default:
		return false
	}
}

func (s JobStatus) Validate() error {
	if s == "" {
		return InvalidInput(ErrStatusRequired)
	}
	if !s.isValid() {
		return InvalidInput(ErrStatusInvalid, "got=%q", s.String())
	}
	return nil
}

func (s JobStatus) IsFinal() bool {
	switch s {
	case JobReady, JobFailed:
		return true
	default:
		return false
	}
}
