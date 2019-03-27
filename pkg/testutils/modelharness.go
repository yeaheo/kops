/*
Copyright 2018 The Kubernetes Authors.

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

package testutils

import (
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"sort"
	"strings"
	"testing"

	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/kops/pkg/apis/kops"
	"k8s.io/kops/pkg/apis/kops/v1alpha2"
	"k8s.io/kops/pkg/diff"
	"k8s.io/kops/pkg/kopscodecs"
	"k8s.io/kops/upup/pkg/fi"
	"k8s.io/kops/util/pkg/text"
)

type Model struct {
	Cluster        *kops.Cluster
	InstanceGroups []*kops.InstanceGroup
}

// LoadModel loads a cluster and instancegroups from a cluster.yaml file found in basedir
func LoadModel(basedir string) (*Model, error) {
	clusterYamlPath := path.Join(basedir, "cluster.yaml")
	clusterYaml, err := ioutil.ReadFile(clusterYamlPath)
	if err != nil {
		return nil, fmt.Errorf("error reading file %q: %v", clusterYamlPath, err)
	}

	spec := &Model{}

	sections := text.SplitContentToSections(clusterYaml)
	for _, section := range sections {
		defaults := &schema.GroupVersionKind{
			Group:   v1alpha2.SchemeGroupVersion.Group,
			Version: v1alpha2.SchemeGroupVersion.Version,
		}
		o, gvk, err := kopscodecs.Decode(section, defaults)
		if err != nil {
			return nil, fmt.Errorf("error parsing file %v", err)
		}

		switch v := o.(type) {
		case *kops.Cluster:
			if spec.Cluster != nil {
				return nil, fmt.Errorf("found multiple clusters")
			}
			spec.Cluster = v
		case *kops.InstanceGroup:
			spec.InstanceGroups = append(spec.InstanceGroups, v)

		default:
			return nil, fmt.Errorf("Unhandled kind %q", gvk)
		}
	}

	return spec, nil
}

func ValidateTasks(t *testing.T, basedir string, context *fi.ModelBuilderContext) {
	var keys []string
	for key := range context.Tasks {
		keys = append(keys, key)
	}
	sort.Strings(keys)

	var yamls []string
	for _, key := range keys {
		task := context.Tasks[key]
		yaml, err := kops.ToRawYaml(task)
		if err != nil {
			t.Fatalf("error serializing task: %v", err)
		}
		yamls = append(yamls, strings.TrimSpace(string(yaml)))
	}

	actualTasksYaml := strings.Join(yamls, "\n---\n")

	tasksYamlPath := path.Join(basedir, "tasks.yaml")
	expectedTasksYamlBytes, err := ioutil.ReadFile(tasksYamlPath)
	if err != nil {
		t.Fatalf("error reading file %q: %v", tasksYamlPath, err)
	}

	actualTasksYaml = strings.TrimSpace(actualTasksYaml)
	expectedTasksYaml := strings.TrimSpace(string(expectedTasksYamlBytes))

	if expectedTasksYaml != actualTasksYaml {
		if os.Getenv("HACK_UPDATE_EXPECTED_IN_PLACE") != "" {
			t.Logf("HACK_UPDATE_EXPECTED_IN_PLACE: writing expected output %s", tasksYamlPath)
			if err := ioutil.WriteFile(tasksYamlPath, []byte(actualTasksYaml), 0644); err != nil {
				t.Errorf("error writing expected output %s: %v", tasksYamlPath, err)
			}
		}

		diffString := diff.FormatDiff(expectedTasksYaml, actualTasksYaml)
		t.Logf("diff:\n%s\n", diffString)

		t.Fatalf("tasks differed from expected for test %q", basedir)
	}
}
