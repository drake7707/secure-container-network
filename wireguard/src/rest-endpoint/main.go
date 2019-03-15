package main

import (
	"bytes"
	"flag"
	"fmt"
	"net/http"
	"os/exec"
        "sync"
)

type handler struct {
}

var (
	script *string
        mutex *sync.Mutex
)

func main() {
	script = flag.String("script", "", "The script to execute when a REST call has been received")
	port := flag.String("port", "51820", "The port to listen on")
	flag.Parse()

        mutex = &sync.Mutex{}

	fmt.Printf("Listening on http:" + *port)

	h := handler{}

	http.ListenAndServe(":"+*port, h)
}

func (handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        mutex.Lock()

	runScript(r.Method, r.RequestURI, w)

        mutex.Unlock()
}

func runScript(method string, path string, w http.ResponseWriter) {
	fmt.Println("Executing script " + *script + " " + method + " " + path)

	cmd := exec.Command(*script, method, path)

	var errbuf bytes.Buffer
	cmd.Stderr = &errbuf

	// stream the output to the outstr
	outstr := ""
	stdout, err := cmd.StdoutPipe()

	err = cmd.Start()

	if err != nil {
		fmt.Printf("Err: " + err.Error())
		fmt.Printf(errbuf.String())
		w.WriteHeader(500)
		w.Header().Set("Content-Type", "text/plain")
		w.Write(([]byte)(err.Error()))
	}

	buff := make([]byte, 10)
	var n int
	for err == nil {
		n, err = stdout.Read(buff)
		if n > 0 {
			fmt.Printf(string(buff[:n]))
			outstr += string(buff[:n])
		}
	}

	err = cmd.Wait()

	if err == nil {
		w.WriteHeader(200)
		w.Header().Set("Content-Type", "text/plain")
		w.Write(([]byte)(outstr))
	} else {
		fmt.Printf("Err: " + err.Error())

		w.WriteHeader(500)
		w.Header().Set("Content-Type", "text/plain")
		w.Write(([]byte)("Unable to execute script: " + err.Error()))
	}
}
