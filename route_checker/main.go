package main

import (
	"encoding/json"
	"flag"
	"io/ioutil"
	"log"
	"net"
	"net/http"
)

var (
	lookupName = flag.String("lookup", "nats", "Lookup name")
	server     = flag.String("server", "http://localhost:8222", "NATS URL to query")
)

type routez struct {
	RoutesCount int `json:"num_routes"`
}

func countInstancesInCluster(lookupName string) (int, error) {
	_, srvRecords, err := net.LookupSRV("", "", lookupName)
	if err != nil {
		return 0, err
	}

	return len(srvRecords), nil
}

func main() {
	flag.Parse()

	// if we're the only instance in the cluster, we're good to go
	// otherwise, we need to check if there are any routes established
	// and if not, exit with error.
	instances, err := countInstancesInCluster(*lookupName)
	if err != nil {
		log.Fatalf("There was an error while verifiying if this is the first instance in the cluster: %s\n", err.Error())
	} else {
		log.Printf("There are %d instances in the cluster.", instances)
	}

	if instances > 1 {
		// query NATS monitoring endpoint
		url := *server + "/routez"
		log.Printf("Querying server %s..\n", url)
		res, err := http.Get(url)
		if err != nil {
			log.Fatalf("There was an error while querying %s: %s\n", url, err.Error())
		}

		body, err := ioutil.ReadAll(res.Body)
		if err != nil {
			log.Fatalf("There was an error while reading response: %s\n", err.Error())
		}

		var data routez
		if err := json.Unmarshal(body, &data); err != nil {
			log.Fatalf("There was an error while decoding response: %s\n", err.Error())
		}

		// if enough routes aren't established, exit with error
		if data.RoutesCount < instances-1 {
			log.Fatalf("There aren't enough routes established. Only %d out of %d.", data.RoutesCount, instances-1)
		}
	}
}
