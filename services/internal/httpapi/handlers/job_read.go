package handlers

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"

	"github.com/google/uuid"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/view"
)

type JobReadService interface {
	ListJobs(ctx context.Context, installID uuid.UUID, status *domain.JobStatus, limit, offset int) ([]domain.Job, int, error)
	GetJob(ctx context.Context, installID uuid.UUID, jobID uuid.UUID) (domain.Job, error)
}

type ListJobsHandler struct {
	svc    JobReadService
	logger *slog.Logger
}

func NewListJobsHandler(svc JobReadService, logger *slog.Logger) *ListJobsHandler {
	if logger == nil {
		logger = slog.Default()
	}
	return &ListJobsHandler{svc: svc, logger: logger}
}

func (h *ListJobsHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	deviceID, err := deviceIDFromRequest(r)
	if err != nil {
		writeRequestError(w, err)
		return
	}

	status, err := parseJobStatus(r.URL.Query().Get("status"))
	if err != nil {
		writeError(w, err, h.logger)
		return
	}

	limit, offset, err := parseLimitOffset(r)
	if err != nil {
		writeBadRequest(w, err.Error())
		return
	}

	jobs, total, err := h.svc.ListJobs(r.Context(), deviceID, status, limit, offset)
	if err != nil {
		writeError(w, err, h.logger)
		return
	}

	items := make([]view.Job, 0, len(jobs))
	for _, job := range jobs {
		items = append(items, view.NewJob(job))
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(map[string]any{
		"items": items,
		"total": total,
	}); err != nil {
		h.logger.Error("failed to encode jobs list response", "err", err)
	}
}

type GetJobHandler struct {
	svc    JobReadService
	logger *slog.Logger
}

func NewGetJobHandler(svc JobReadService, logger *slog.Logger) *GetJobHandler {
	if logger == nil {
		logger = slog.Default()
	}
	return &GetJobHandler{svc: svc, logger: logger}
}

func (h *GetJobHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	deviceID, err := deviceIDFromRequest(r)
	if err != nil {
		writeRequestError(w, err)
		return
	}

	jobID, err := uuidPathValue(r, "id")
	if err != nil {
		writeBadRequest(w, "invalid job id")
		return
	}

	job, err := h.svc.GetJob(r.Context(), deviceID, jobID)
	if err != nil {
		writeError(w, err, h.logger)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(view.NewJob(job)); err != nil {
		h.logger.Error("failed to encode get job response", "err", err, "job_id", jobID.String())
	}
}
