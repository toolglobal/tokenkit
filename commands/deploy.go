package commands

import (
	"encoding/hex"
	"fmt"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/spf13/cobra"
	"github.com/wolot/gosdk"
	"math/big"
	"strings"
)

func NewDeployCmd() *cobra.Command {
	var cmd = &cobra.Command{
		Use:   "deploy",
		Short: "deploy contract",
		RunE:  deploy,
	}
	cmd.Flags().String("api", "http://192.168.10.106:8889", "Mondo[OLO] API,like https://olo.ibdt.tech")
	cmd.Flags().String("name", "", "token name")
	cmd.Flags().String("symbol", "", "token symbol,like BTC")
	cmd.Flags().String("supply", "", "init supply")
	cmd.Flags().String("key", "", "private key")
	return cmd
}

func deploy(cmd *cobra.Command, args []string) error {
	abiIns, err := abi.JSON(strings.NewReader(XYZTokenABI))
	if err != nil {
		panic(err)
	}

	name, _ := cmd.Flags().GetString("name")
	symbol, _ := cmd.Flags().GetString("symbol")
	supply, _ := cmd.Flags().GetString("supply")

	initSupply, _ := new(big.Int).SetString(supply, 10)
	initSupply = new(big.Int).Mul(initSupply, big.NewInt(1e8))
	bz, err := abiIns.Pack("", initSupply, name, symbol, uint8(8))
	if err != nil {
		panic(err)
	}

	bytecode := "0x" + XYZToeknBytecode + hex.EncodeToString(bz)

	key, _ := cmd.Flags().GetString("key")
	privkey, err := crypto.ToECDSA(common.Hex2Bytes(key))
	if err != nil {
		return err
	}
	publicKey := common.Bytes2Hex(crypto.CompressPubkey(&privkey.PublicKey))

	api, _ := cmd.Flags().GetString("api")
	hash, contract, gasUsed, err := gosdk.NewAPIClient(api).DeployTx("", publicKey, key, "0", bytecode, 3000000, "1", "")
	fmt.Printf("hash:%s contract:%s gasUsed:%v err:%v\n", hash, contract, gasUsed, err)
	return nil
}
