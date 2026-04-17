// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: SUSE LLC
// SPDX-FileCopyrightText: The Rancher Desktop Authors

package controllers

import (
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/containerd/errdefs"
	"github.com/gorilla/websocket"
	"github.com/moby/moby/api/pkg/stdcopy"
	"github.com/moby/moby/client"

	ctrl "sigs.k8s.io/controller-runtime"
)

var containerIDValidator = regexp.MustCompile(`^[0-9a-fA-F]+$`)

// HandleLogs implements the log endpoint to pass through container logs.
func (r *EngineReconciler) HandleLogs(w http.ResponseWriter, req *http.Request) {
	log := ctrl.LoggerFrom(req.Context())
	containerID, _, _ := strings.Cut(strings.TrimLeft(req.URL.Path, "/"), "/")
	log.Info("Handling logs for container", "containerID", containerID)

	if !containerIDValidator.MatchString(containerID) {
		log.V(5).Info("Invalid container ID", "container", containerID)
		http.Error(w, "Invalid container ID", http.StatusBadRequest)
		return
	}

	// TODO: Figure out containerd
	reader, err := r.watcher.cli.ContainerLogs(
		req.Context(),
		containerID,
		client.ContainerLogsOptions{
			ShowStdout: true,
			ShowStderr: true,
			Follow:     true,
		},
	)
	if err != nil {
		switch {
		case errdefs.IsNotFound(err):
			log.V(5).Info("Container not found", "container", containerID)
			http.Error(w, "Container not found", http.StatusNotFound)
		case errdefs.IsInvalidArgument(err):
			log.V(5).Info("Invalid argument", "error", err)
			http.Error(w, "Invalid argument", http.StatusBadRequest)
		default:
			log.V(5).Info("Failed to get container logs", "error", err)
			http.Error(w, "Failed to get container logs", http.StatusInternalServerError)
		}
		return
	}

	upgrader := websocket.Upgrader{}
	conn, err := upgrader.Upgrade(w, req, nil)
	if err != nil {
		log.V(5).Info("Failed to upgrade to WebSocket", "error", err)
		return
	}
	defer conn.Close()
	defer func() {
		message := websocket.FormatCloseMessage(websocket.CloseNormalClosure, "Closing connection")
		err := conn.WriteControl(websocket.CloseMessage, message, time.Now().Add(time.Second))
		if err != nil {
			log.V(5).Info("Failed to close WebSocket", "error", err)
		}
	}()

	writer, err := conn.NextWriter(websocket.TextMessage)
	if err != nil {
		log.V(5).Info("Failed to get next writer", "error", err)
		return
	}
	defer writer.Close()

	_, err = stdcopy.StdCopy(writer, writer, reader)
	if err != nil {
		log.V(5).Info("Failed to copy container logs", "error", err)
		// At this point we already sent the data, so we can't send HTTP status.
	}
}
