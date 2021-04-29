package commands

import (
	"fmt"
	"github.com/spf13/cobra"
)

var (
	CoreSemVer string
)

func init() {
	CoreSemVer = "v0.0.1"
}

var VersionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show version info",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(CoreSemVer)
	},
}
