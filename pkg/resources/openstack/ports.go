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

package openstack

import (
	"strings"

	"github.com/gophercloud/gophercloud/openstack/networking/v2/ports"
	"k8s.io/kops/pkg/resources"
	"k8s.io/kops/upup/pkg/fi"
	"k8s.io/kops/upup/pkg/fi/cloudup/openstack"
)

const (
	typePort = "Port"
)

func (os *clusterDiscoveryOS) ListPorts() ([]*resources.Resource, error) {
	var resourceTrackers []*resources.Resource

	ports, err := os.osCloud.ListPorts(ports.ListOpts{})
	if err != nil {
		return nil, err
	}

	for _, port := range ports {
		clusteReplaced := strings.Replace(os.clusterName, ".", "-", -1)
		if strings.HasSuffix(port.Name, clusteReplaced) {
			resourceTracker := &resources.Resource{
				Name: port.Name,
				ID:   port.ID,
				Type: typePort,
				Deleter: func(cloud fi.Cloud, r *resources.Resource) error {
					return cloud.(openstack.OpenstackCloud).DeletePort(r.ID)
				},
			}
			resourceTrackers = append(resourceTrackers, resourceTracker)
		}
	}
	return resourceTrackers, nil
}
