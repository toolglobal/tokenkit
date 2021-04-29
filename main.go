package main

import "tokenkit/commands"

// 发行代币
func main() {
	var rootCmd = commands.RootCmd
	rootCmd.AddCommand(commands.NewDeployCmd(),
		commands.NewDBalanceOfCmd(),
		commands.NewIssueCmd(),
		commands.NewRedeemCmd())
	if err := rootCmd.Execute(); err != nil {
		panic(err)
	}
}
