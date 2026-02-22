package handlers

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/httpapi/dto"
)

// интерфейс сервиса — то, что нужно handler'у.
type JobService interface {
	CreateJob(ctx context.Context, req dto.CreateJobRequest) (dto.Job, error)
}

// JobsHandler — HTTP обработчик для /jobs.
type JobsHandler struct {
	svc JobService
}

// NewJobsHandler — конструктор handler'а.
func NewJobsHandler(svc JobService) *JobsHandler {
	return &JobsHandler{svc: svc}
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

// POST /jobs
func (h *JobsHandler) handleCreateJob(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	var req dto.CreateJobRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid json: "+err.Error(), http.StatusBadRequest)
		return
	}

	// (Пока без X-Device-Id / User — просто создаём job)
	job, err := h.svc.CreateJob(r.Context(), req)
	if err != nil {
		// примитивно мапим всё в 400 — потом разделим на разные коды
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(job)
}