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

package aws

import (
	"reflect"
	"sort"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"k8s.io/kops/cloudmock/aws/mockec2"
	"k8s.io/kops/pkg/resources"
	"k8s.io/kops/upup/pkg/fi/cloudup/awsup"
)

func TestAddUntaggedRouteTables(t *testing.T) {
	cloud := awsup.BuildMockAWSCloud("us-east-1", "abc")
	resourceTrackers := make(map[string]*resources.Resource)

	clusterName := "me.example.com"

	c := &mockec2.MockEC2{}
	cloud.MockEC2 = c

	// Matches by vpc id
	c.AddRouteTable(&ec2.RouteTable{
		VpcId:        aws.String("vpc-1234"),
		RouteTableId: aws.String("rtb-1234"),
	})

	// Skips main route tables
	c.AddRouteTable(&ec2.RouteTable{
		VpcId:        aws.String("vpc-1234"),
		RouteTableId: aws.String("rtb-1234main"),
		Associations: []*ec2.RouteTableAssociation{
			{
				Main: aws.Bool(true),
			},
		},
	})

	// Skips route table tagged with other cluster
	c.AddRouteTable(&ec2.RouteTable{
		VpcId:        aws.String("vpc-1234"),
		RouteTableId: aws.String("rtb-1234notmain"),
		Tags: []*ec2.Tag{
			{
				Key:   aws.String(awsup.TagClusterName),
				Value: aws.String("other.example.com"),
			},
		},
	})

	// Ignores non-matching vpcs
	c.AddRouteTable(&ec2.RouteTable{
		VpcId:        aws.String("vpc-5555"),
		RouteTableId: aws.String("rtb-5555"),
	})

	resourceTrackers["vpc:vpc-1234"] = &resources.Resource{}

	err := addUntaggedRouteTables(cloud, clusterName, resourceTrackers)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var keys []string
	for k := range resourceTrackers {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	expected := []string{"route-table:rtb-1234", "vpc:vpc-1234"}
	if !reflect.DeepEqual(expected, keys) {
		t.Fatalf("expected=%q, actual=%q", expected, keys)
	}
}

func TestListRouteTables(t *testing.T) {
	cloud := awsup.BuildMockAWSCloud("us-east-1", "abc")
	//resources := make(map[string]*Resource)
	clusterName := "me.example.com"
	ownershipTagKey := "kubernetes.io/cluster/" + clusterName

	c := &mockec2.MockEC2{}
	cloud.MockEC2 = c

	c.AddRouteTable(&ec2.RouteTable{
		VpcId:        aws.String("vpc-1234"),
		RouteTableId: aws.String("rtb-shared"),
		Tags: []*ec2.Tag{
			{
				Key:   aws.String("KubernetesCluster"),
				Value: aws.String(clusterName),
			},
			{
				Key:   aws.String(ownershipTagKey),
				Value: aws.String("shared"),
			},
		},
	})
	c.AddRouteTable(&ec2.RouteTable{
		VpcId:        aws.String("vpc-1234"),
		RouteTableId: aws.String("rtb-owned"),
		Tags: []*ec2.Tag{
			{
				Key:   aws.String("KubernetesCluster"),
				Value: aws.String(clusterName),
			},
			{
				Key:   aws.String(ownershipTagKey),
				Value: aws.String("owned"),
			},
		},
	})

	resourceTrackers, err := ListRouteTables(cloud, clusterName)
	if err != nil {
		t.Fatalf("error listing route tables: %v", err)
	}
	for _, rt := range resourceTrackers {
		if rt.ID == "rtb-shared" && !rt.Shared {
			t.Fatalf("expected Shared: true, got: %v", rt.Shared)
		}
		if rt.ID == "rtb-owned" && rt.Shared {
			t.Fatalf("expected Shared: false, got: %v", rt.Shared)
		}
	}
}
