package commands

import (
	"fmt"
	"github.com/spf13/cobra"
	"github.com/wolot/gosdk"
)

func NewDBalanceOfCmd() *cobra.Command {
	var cmd = &cobra.Command{
		Use:   "balanceOf",
		Short: "address balanceOf Token",
		RunE:  balanceOf,
	}
	cmd.Flags().String("api", "http://192.168.10.106:8889", "Mondo[OLO] API,like https://olo.ibdt.tech")
	cmd.Flags().String("token", "", "token contract")
	cmd.Flags().String("address", "", "address")
	return cmd
}

func balanceOf(cmd *cobra.Command, args []string) error {
	api, _ := cmd.Flags().GetString("api")
	mondoCli := gosdk.NewAPIClient(api)
	pubKey, _, priKey, _ := gosdk.GenKey()
	token, _ := cmd.Flags().GetString("token")
	address, _ := cmd.Flags().GetString("address")

	bal, err := mondoCli.ERC20BalanceOf(pubKey, priKey, token, address)
	fmt.Printf("balance:%v err:%v\n", bal.String(), err)
	return nil
}
