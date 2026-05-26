package realtime

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/view"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 90 * time.Second
	pingPeriod     = 30 * time.Second
	maxMessageSize = 1 << 20
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

type Hub struct {
	logger *slog.Logger

	mu      sync.RWMutex
	clients map[uuid.UUID]map[*client]struct{}
}

type client struct {
	hub    *Hub
	conn   *websocket.Conn
	userID uuid.UUID
	logger *slog.Logger
	send   chan []byte
	once   sync.Once
}

func NewHub(logger *slog.Logger) *Hub {
	if logger == nil {
		logger = slog.Default()
	}

	return &Hub{
		logger:  logger,
		clients: make(map[uuid.UUID]map[*client]struct{}),
	}
}

func (h *Hub) ServeWS(w http.ResponseWriter, r *http.Request, userID uuid.UUID) error {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		return err
	}

	c := &client{
		hub:    h,
		conn:   conn,
		userID: userID,
		logger: h.logger,
		send:   make(chan []byte, 16),
	}

	h.register(c)

	go c.writePump()
	go c.readPump()

	return nil
}

func (h *Hub) BroadcastJobUpdated(userID uuid.UUID, job view.Job) {
	payload, err := json.Marshal(NewWSJobUpdated(job))
	if err != nil {
		h.logger.Error("failed to marshal ws job update", "err", err, "user_id", userID.String(), "job_id", job.ID)
		return
	}
	h.broadcast(userID, payload)
}

func (h *Hub) register(c *client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if _, ok := h.clients[c.userID]; !ok {
		h.clients[c.userID] = make(map[*client]struct{})
	}
	h.clients[c.userID][c] = struct{}{}
	h.logger.Info("ws client connected", "user_id", c.userID.String(), "connections", len(h.clients[c.userID]))
}

func (h *Hub) unregister(c *client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	clients := h.clients[c.userID]
	if clients == nil {
		return
	}
	delete(clients, c)
	if len(clients) == 0 {
		delete(h.clients, c.userID)
	}
	close(c.send)
	h.logger.Info("ws client disconnected", "user_id", c.userID.String(), "connections", len(clients))
}

func (h *Hub) broadcast(userID uuid.UUID, payload []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	for c := range h.clients[userID] {
		select {
		case c.send <- payload:
		default:
			go c.close()
		}
	}
}

func (c *client) readPump() {
	defer c.close()

	c.conn.SetReadLimit(maxMessageSize)
	_ = c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		return c.conn.SetReadDeadline(time.Now().Add(pongWait))
	})

	for {
		var msg WSClientMessage
		if err := c.conn.ReadJSON(&msg); err != nil {
			return
		}

		if msg.Type == WSClientEventPing {
			payload, err := json.Marshal(NewWSPong())
			if err != nil {
				return
			}
			select {
			case c.send <- payload:
			default:
				return
			}
		}
	}
}

func (c *client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer ticker.Stop()
	defer c.close()

	for {
		select {
		case payload, ok := <-c.send:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				_ = c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, payload); err != nil {
				return
			}
		case <-ticker.C:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (c *client) close() {
	c.once.Do(func() {
		c.hub.unregister(c)
		_ = c.conn.Close()
	})
}
