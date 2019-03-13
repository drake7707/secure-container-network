package main

import (
	"flag"
	"fmt"
	"net/http"
)

type handler struct {
}

var (
	script *string
)

func main() {
	port := flag.String("port", "1500", "The port to listen on")
	flag.Parse()

	fmt.Printf("Listening on http:" + *port)

	h := handler{}

	http.ListenAndServe(":"+*port, h)
}

func (handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
       outstr := "OK"
       w.WriteHeader(200)
       w.Header().Set("Content-Type", "text/plain")
       w.Write(([]byte)(outstr))
}


