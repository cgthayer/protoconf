package golangimporter

import (
	"io/ioutil"
	"log"
	"path/filepath"
	"strings"
	"testing"

	"github.com/jhump/protoreflect/desc/builder"
	"github.com/mitchellh/go-homedir"
	assert "github.com/stretchr/testify/require"
)

func TestGolangImporter(t *testing.T) {
	outputdir, err := ioutil.TempDir("", "go_importer_test")
	assert.NoError(t, err, "failed to create tmp folder")
	userHome, err := homedir.Dir()
	assert.NoError(t, err, "could not get homedir")

	// packageID := "github.com/hashicorp/nomad/api"
	// outputdir = "/tmp/importers/golang/nomad"

	packageID := "github.com/prometheus/prometheus/config"
	outputdir = "/tmp/importers/golang/prometheus"

	i, err := NewGolangImporter(
		packageID,
		outputdir,
		filepath.Join(userHome, "go", "src"),
		"HOME="+userHome,
	)
	assert.NoError(t, err, "failed to create GolangImporter")
	importer := i.GetImporter()
	filtered := importer.FilterFiles("prometheus_config", "Config")
	importer.Files = filtered
	err = importer.SaveAll()
	assert.NoError(t, err, "failed to save files")
}

func printProto(b builder.Builder, indent int) {
	indentStr := strings.Repeat("  ", indent)
	if b.GetParent() != nil {
		log.Println(indentStr, "in:", b.GetParent().GetName(), b.GetName())
	} else {
		log.Println(indentStr, "in:", b.GetName())
	}
	for _, child := range b.GetChildren() {
		printProto(child, indent+1)
		if field, ok := child.(*builder.FieldBuilder); ok {
			log.Println(indentStr, "type:", field.GetType().GetTypeName(), field.GetType())
			subType := field.GetType()
			if subType != nil {
				log.Println(indentStr, "file:", subType.GetType().String())
			}
		}
	}
}
