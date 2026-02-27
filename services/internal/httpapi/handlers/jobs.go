package handlers

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"github.com/google/uuid"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/httpapi/dto"
)

// интерфейс сервиса — то, что нужно handler'у.
// ВАЖНО: сервис не зависит от dto (dto это http слой) => сервис работает с доменом
type JobService interface {
	CreateJob(ctx context.Context, deviceID uuid.UUID, params domain.JobParams) (domain.Job, error)
}

// JobsHandler — HTTP обработчик для /jobs.
type JobsHandler struct {
	svc    JobService
	logger *slog.Logger
}

// NewJobsHandler — конструктор handler'а.
func NewJobsHandler(svc JobService, logger *slog.Logger) *JobsHandler {
	if logger == nil {
		logger = slog.Default()
	}
	return &JobsHandler{svc: svc, logger: logger}
}

// ServeHTTP — точка входа для /jobs.
func (h *JobsHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodPost:
		h.handleCreateJob(w, r)
	default:
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	}
}

// deviceIDFromRequest — парсит обязательный хедер X-Device-Id.
func deviceIDFromRequest(r *http.Request) (uuid.UUID, error) {
	raw := r.Header.Get("X-Device-Id")
	if raw == "" {
		return uuid.Nil, errors.New("X-Device-Id is required")
	}
	return uuid.Parse(raw)
}

// POST /jobs
func (h *JobsHandler) handleCreateJob(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	// X-Device-Id — обязательный хедер
	deviceID, err := deviceIDFromRequest(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	var req dto.CreateJobRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid json: "+err.Error(), http.StatusBadRequest)
		return
	}

	// dto -> domain
	params := req.ToJobParams()
	params.Normalize()

	//  добавили валидацию до вызова сервиса
	if err := params.Validate(); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// сервис принимает домен и возвращает домен
	job, err := h.svc.CreateJob(r.Context(), deviceID, params)
	if err != nil {
		//  разделяем на sentinel-ошибки через switch-case (вынесено в errors.go)
		writeError(w, err, h.logger)
		return
	}

	// domain -> dto
	resp := dto.NewJob(job)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)

	// не игнорируем encode: логируем ошибку
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		h.logger.Error(
			"failed to encode create job response",
			"err", err,
			"job_id", job.ID.String(),
			"device_id", deviceID.String(),
		)
	}
}