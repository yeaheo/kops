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

package k8scodecs

import (
	"strings"
	"testing"
	"time"

	"github.com/MakeNowJust/heredoc"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/kops/pkg/diff"
)

// An arbitrary timestamp for testing
var testTimestamp = metav1.Time{Time: time.Date(2017, 1, 1, 0, 0, 0, 0, time.UTC)}

func TestToVersionedYaml(t *testing.T) {
	grid := []struct {
		obj      runtime.Object
		expected string
	}{
		{
			obj: &v1.Pod{
				ObjectMeta: metav1.ObjectMeta{
					CreationTimestamp: testTimestamp,
					Name:              "hello",
				},
				Spec: v1.PodSpec{
					Containers: []v1.Container{
						{
							Name: "container1",
						},
					},
				},
			},
			expected: heredoc.Doc(`
			apiVersion: v1
			kind: Pod
			metadata:
			  creationTimestamp: "2017-01-01T00:00:00Z"
			  name: hello
			spec:
			  containers:
			  - name: container1
			    resources: {}
			status: {}
			`),
		},
	}
	for _, g := range grid {
		actualBytes, err := ToVersionedYaml(g.obj)
		if err != nil {
			t.Errorf("error from ToVersionedYaml: %v", err)
			continue
		}
		actual := string(actualBytes)
		actual = strings.TrimSpace(actual)
		expected := strings.TrimSpace(g.expected)
		if actual != expected {
			t.Logf(diff.FormatDiff(actual, expected))
			t.Errorf("actual != expected")
			continue
		}
	}

}
