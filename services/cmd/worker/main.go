package main

import (
	"log"
	"time"
)

func main() {
	log.Println("worker started")
	for {
		time.Sleep(10 * time.Second)
		log.Println("worker heartbeat")
	}
}
