package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"os"
)

const NO_ROUTEZ_ESTABLISHED = 1

var (
	lookupName = flag.String("lookup", "nats", "Lookup name")
	server     = flag.String("server", "localhost", "NATS server to query")
)

type routez struct {
	num_routez uint
}

func isFirstNatsInstanceInCluster(lookupName string) (bool, error) {
	_, srvRecords, err := net.LookupSRV("", "", lookupName)
	if err != nil {
		return false, err
	}

	return len(srvRecords) == 1, nil
}

func main() {
	flag.Parse()

	// if we're the only instance in the cluster, we're good to go
	// otherwise, we need to check if there are any routez established
	// and if not, exit with error.
	isFirst, err := isFirstNatsInstanceInCluster(*lookupName)
	if err != nil {
		panic(err.Error())
	}

	if !isFirst {
		// query NATS monitoring endpoint
		url := "http://" + *server + "/routez"
		fmt.Printf("Querying server %s..\n", url)
		res, err := http.Get(url)
		if err != nil {
			panic(err.Error())
		}

		body, err := ioutil.ReadAll(res.Body)
		if err != nil {
			panic(err.Error())
		}

		var data routez
		if err := json.Unmarshal(body, &data); err != nil {
			panic(err)
		}

		// if no routes are established, exit with error
		if data.num_routez == 0 {
			os.Exit(NO_ROUTEZ_ESTABLISHED)
		}
	}
}
