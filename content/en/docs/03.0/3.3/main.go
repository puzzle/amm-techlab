package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

func main() {

	_, err := createFile("/home/golang/hello-go.log")
	if err != nil {
		panic(err)
	}

	http.HandleFunc("/", HelloServer)
	http.ListenAndServe(":8080", nil)
}

func HelloServer(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello, %s!", r.URL.Path[1:])
	appendToFile(r.RemoteAddr)
}

func createFile(p string) (*os.File, error) {
	if err := os.MkdirAll(filepath.Dir(p), 0644); err != nil {
		return nil, err
	}
	return os.Create(p)
}

func appendToFile(remoteAddr string) {
	f, err := os.OpenFile("/home/golang/hello-go.log", os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		log.Println(err)
	}
	defer f.Close()

	line := fmt.Sprintf("%s: Request from: %s\n", time.Now().String(), remoteAddr)

	if _, err := f.WriteString(line); err != nil {
		log.Println(err)
	}
}
