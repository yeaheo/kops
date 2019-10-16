/*
Copyright 2019 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package memberlist

import (
	"context"
	"fmt"
	"net"
	"strconv"
	"strings"
	"time"

	cluster "github.com/jacksontj/memberlistmesh"
	"github.com/prometheus/client_golang/prometheus"
	"k8s.io/klog"
	"k8s.io/kops/protokube/pkg/gossip"
)

func init() {
	gossip.Register("memberlist", func(listen, channelName, gossipName string, gossipSecret []byte, gossipSeeds gossip.SeedProvider) (gossip.GossipState, error) {
		return NewMemberlistGossiper(listen, channelName, gossipName, gossipSecret, gossipSeeds)
	})
}

type MemberlistGossiper struct {
	peer       *cluster.Peer
	seeds      gossip.SeedProvider
	listenPort int

	state *state
	bcast func([]byte)
}

func NewMemberlistGossiper(listen string, channelName string, nodeName string, password []byte, seeds gossip.SeedProvider) (*MemberlistGossiper, error) {
	_, portString, err := net.SplitHostPort(listen)
	if err != nil {
		return nil, fmt.Errorf("cannot parse -listen flag: %v", listen)
	}
	port, err := strconv.Atoi(portString)
	if err != nil {
		return nil, fmt.Errorf("cannot parse -listen flag: %v", listen)
	}

	initialPeers, err := seeds.GetSeeds()
	if err != nil {
		return nil, err
	}
	// TODO: get port from other config?
	for i, initialPeer := range initialPeers {
		if !strings.Contains(initialPeer, ":") {
			initialPeers[i] = initialPeer + ":" + strconv.Itoa(port)
		}
	}

	peer, err := cluster.Create(
		prometheus.DefaultRegisterer,
		listen,
		"", //*clusterAdvertiseAddr,
		initialPeers,
		true,
		cluster.DefaultPushPullInterval,
		cluster.DefaultGossipInterval,
		cluster.DefaultTcpTimeout,
		cluster.DefaultProbeTimeout,
		cluster.DefaultProbeInterval,
	)
	if err != nil {
		return nil, err
	}

	s := &state{}

	return &MemberlistGossiper{
		peer:       peer,
		seeds:      seeds,
		listenPort: port,
		state:      s,
		bcast:      peer.AddState(channelName, s, prometheus.DefaultRegisterer).Broadcast,
	}, nil
}

func (g *MemberlistGossiper) Start() error {
	if err := g.peer.Join(cluster.DefaultReconnectInterval, cluster.DefaultReconnectTimeout); err != nil {
		return err
	}
	ctx, cancel := context.WithTimeout(context.Background(), cluster.DefaultPushPullInterval)
	defer func() {
		cancel()
		if err := g.peer.Leave(10 * time.Second); err != nil {
			klog.V(2).Infof("unable to leave gossip mesh: %v", err)
		}
	}()

	g.peer.Settle(ctx, cluster.DefaultGossipInterval*10)
	g.runSeeding()

	return nil
}

func (g *MemberlistGossiper) runSeeding() {
SEED_LOOP:
	for {
		klog.V(2).Infof("Querying for seeds")

		seeds, err := g.seeds.GetSeeds()
		if err != nil {
			klog.Warningf("error getting seeds: %v", err)
			time.Sleep(1 * time.Minute)
			continue
		}
		klog.Infof("Got seeds: %s", seeds)

		for _, seed := range seeds {
			if !strings.Contains(seed, ":") {
				seed = seed + ":" + strconv.Itoa(g.listenPort)
			}
			if err := g.peer.AddPeer(seed); err != nil {
				klog.Infof("error connecting to seeds: %v", err)
				time.Sleep(1 * time.Minute)
				continue SEED_LOOP
			}
		}

		klog.V(2).Infof("Seeding successful")

		// Reseed periodically, just in case of partitions
		// TODO: Make it so that only one node polls, or at least statistically get close
		time.Sleep(60 * time.Minute)
	}
}

func (g *MemberlistGossiper) Snapshot() *gossip.GossipStateSnapshot {
	return g.state.snapshot()
}

func (g *MemberlistGossiper) UpdateValues(removeKeys []string, putKeys map[string]string) error {
	klog.V(2).Infof("UpdateValues: remove=%s, put=%s", removeKeys, putKeys)
	g.state.updateValues(removeKeys, putKeys)
	b, err := g.state.MarshalBinary()
	if err != nil {
		return err
	}
	g.bcast(b)
	return nil
}
