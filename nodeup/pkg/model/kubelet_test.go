/*
Copyright 2017 The Kubernetes Authors.

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

package model

import (
	"fmt"
	"testing"

	"k8s.io/kops/nodeup/pkg/distros"
	"k8s.io/kops/pkg/apis/kops"
	"k8s.io/kops/pkg/testutils"
	"k8s.io/kops/upup/pkg/fi"
)

func Test_InstanceGroupKubeletMerge(t *testing.T) {
	var cluster = &kops.Cluster{}
	cluster.Spec.Kubelet = &kops.KubeletConfigSpec{}
	cluster.Spec.Kubelet.NvidiaGPUs = 0
	cluster.Spec.KubernetesVersion = "1.6.0"

	var instanceGroup = &kops.InstanceGroup{}
	instanceGroup.Spec.Kubelet = &kops.KubeletConfigSpec{}
	instanceGroup.Spec.Kubelet.NvidiaGPUs = 1
	instanceGroup.Spec.Role = kops.InstanceGroupRoleNode

	b := &KubeletBuilder{
		&NodeupModelContext{
			Cluster:       cluster,
			InstanceGroup: instanceGroup,
		},
	}
	if err := b.Init(); err != nil {
		t.Error(err)
	}

	var mergedKubeletSpec, err = b.buildKubeletConfigSpec()
	if err != nil {
		t.Error(err)
	}
	if mergedKubeletSpec == nil {
		t.Error("Returned nil kubelet spec")
	}

	if mergedKubeletSpec.NvidiaGPUs != instanceGroup.Spec.Kubelet.NvidiaGPUs {
		t.Errorf("InstanceGroup kubelet value (%d) should be reflected in merged output", instanceGroup.Spec.Kubelet.NvidiaGPUs)
	}
}

func TestTaintsAppliedAfter160(t *testing.T) {
	tests := []struct {
		version           string
		taints            []string
		expectError       bool
		expectSchedulable bool
		expectTaints      []string
	}{
		{
			version: "1.4.9",
		},
		{
			version: "1.5.2",
			taints:  []string{"foo"},
		},
		{
			version:           "1.6.0-alpha.1",
			taints:            []string{"foo"},
			expectTaints:      []string{"foo"},
			expectSchedulable: true,
		},
		{
			version:           "1.6.0",
			taints:            []string{"foo", "bar"},
			expectTaints:      []string{"foo", "bar"},
			expectSchedulable: true,
		},
		{
			version:           "1.7.0",
			taints:            []string{"foo", "bar", "baz"},
			expectTaints:      []string{"foo", "bar", "baz"},
			expectSchedulable: true,
		},
	}

	for _, g := range tests {
		cluster := &kops.Cluster{Spec: kops.ClusterSpec{KubernetesVersion: g.version}}
		ig := &kops.InstanceGroup{Spec: kops.InstanceGroupSpec{Role: kops.InstanceGroupRoleMaster, Taints: g.taints}}

		b := &KubeletBuilder{
			&NodeupModelContext{
				Cluster:       cluster,
				InstanceGroup: ig,
			},
		}
		if err := b.Init(); err != nil {
			t.Error(err)
		}

		c, err := b.buildKubeletConfigSpec()

		if g.expectError {
			if err == nil {
				t.Fatalf("Expected error but did not get one for version %q", g.version)
			}

			continue
		} else {
			if err != nil {
				t.Fatalf("Unexpected error for version %q: %v", g.version, err)
			}
		}

		if fi.BoolValue(c.RegisterSchedulable) != g.expectSchedulable {
			t.Fatalf("Expected RegisterSchedulable == %v, got %v (for %v)", g.expectSchedulable, fi.BoolValue(c.RegisterSchedulable), g.version)
		}

		if !stringSlicesEqual(g.expectTaints, c.Taints) {
			t.Fatalf("Expected taints %v, got %v", g.expectTaints, c.Taints)
		}
	}
}

func stringSlicesEqual(exp, other []string) bool {
	if exp == nil && other != nil {
		return false
	}

	if exp != nil && other == nil {
		return false
	}

	if len(exp) != len(other) {
		return false
	}

	for i, e := range exp {
		if other[i] != e {
			return false
		}
	}

	return true
}

func Test_RunKubeletBuilder(t *testing.T) {
	basedir := "tests/kubelet/featuregates"

	context := &fi.ModelBuilderContext{
		Tasks: make(map[string]fi.Task),
	}
	nodeUpModelContext, err := BuildNodeupModelContext(basedir)
	if err != nil {
		t.Fatalf("error loading model %q: %v", basedir, err)
		return
	}

	builder := KubeletBuilder{NodeupModelContext: nodeUpModelContext}

	kubeletConfig, err := builder.buildKubeletConfig()
	if err != nil {
		t.Fatalf("error from KubeletBuilder buildKubeletConfig: %v", err)
		return
	}

	fileTask, err := builder.buildSystemdEnvironmentFile(kubeletConfig)
	if err != nil {
		t.Fatalf("error from KubeletBuilder buildSystemdEnvironmentFile: %v", err)
		return
	}
	context.AddTask(fileTask)

	{
		task, err := builder.buildManifestDirectory(kubeletConfig)
		if err != nil {
			t.Fatalf("error from KubeletBuilder buildManifestDirectory: %v", err)
			return
		}
		context.AddTask(task)
	}

	{
		task := builder.buildSystemdService()
		if err != nil {
			t.Fatalf("error from KubeletBuilder buildSystemdService: %v", err)
			return
		}
		context.AddTask(task)
	}

	testutils.ValidateTasks(t, basedir, context)
}

func BuildNodeupModelContext(basedir string) (*NodeupModelContext, error) {
	model, err := testutils.LoadModel(basedir)
	if err != nil {
		return nil, err
	}

	if model.Cluster == nil {
		return nil, fmt.Errorf("no cluster found in %s", basedir)
	}

	nodeUpModelContext := &NodeupModelContext{
		Cluster:      model.Cluster,
		Architecture: "amd64",
		Distribution: distros.DistributionXenial,
	}

	if len(model.InstanceGroups) == 0 {
		// We tolerate this - not all tests need an instance group
	} else if len(model.InstanceGroups) == 1 {
		nodeUpModelContext.InstanceGroup = model.InstanceGroups[0]
	} else {
		return nil, fmt.Errorf("unexpected number of instance groups in %s, found %d", basedir, len(model.InstanceGroups))
	}

	if err := nodeUpModelContext.Init(); err != nil {
		return nil, err
	}

	return nodeUpModelContext, nil
}
