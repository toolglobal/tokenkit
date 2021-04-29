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

func NewRedeemCmd() *cobra.Command {
	var cmd = &cobra.Command{
		Use:   "redeem",
		Short: "redeem[burn] amount",
		RunE:  redeem,
	}
	cmd.Flags().String("api", "http://192.168.10.106:8889", "Mondo[OLO] API,like https://olo.ibdt.tech")
	cmd.Flags().String("token", "", "token contract")
	cmd.Flags().String("amount", "", "amount")
	cmd.Flags().String("key", "", "private key")
	return cmd
}

func redeem(cmd *cobra.Command, args []string) error {
	abiIns, err := abi.JSON(strings.NewReader(XYZTokenABI))
	if err != nil {
		panic(err)
	}

	amounts, _ := cmd.Flags().GetString("amount")

	amount, _ := new(big.Int).SetString(amounts, 10)
	amount = new(big.Int).Mul(amount, big.NewInt(1e8))
	bz, err := abiIns.Pack("redeem", amount)
	if err != nil {
		panic(err)
	}

	key, _ := cmd.Flags().GetString("key")
	privkey, err := crypto.ToECDSA(common.Hex2Bytes(key))
	if err != nil {
		return err
	}
	publicKey := common.Bytes2Hex(crypto.CompressPubkey(&privkey.PublicKey))

	token, _ := cmd.Flags().GetString("token")

	api, _ := cmd.Flags().GetString("api")
	hash, _, gasUsed, err := gosdk.NewAPIClient(api).InvokeTx("", publicKey, key, token, "0", hex.EncodeToString(bz), 3000000, "1", "")
	fmt.Printf("hash:%s gasUsed:%v err:%v\n", hash, gasUsed, err)
	return nil
}
