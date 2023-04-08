package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"io/ioutil"
	"math/big"
	"net/http"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"gopkg.in/yaml.v3"
)

type TransactionRequest struct {
	Target   common.Address `json:"target" binding:"required"`
	CallData string         `json:"callData" binding:"required"`
}

type Transaction struct {
	TxHash   string         `json:"txHash"`
	Target   common.Address `json:"Target"`
	CallData common.Hash    `json:"callData"`
	SendTime int64          `json:"sendTime"`
	Status   string         `json:"status"`
}

func init() {
	if err := loadConfig("config.yaml"); err != nil {
		panic(fmt.Errorf("failed to load config: %v", err))
	}
}

func main() {

	router := gin.Default()

	// 添加CORS中间件
	router.Use(cors.New(cors.Config{
		AllowMethods:     []string{"POST", "OPTION"},
		AllowHeaders:     []string{"Origin", "Content-Type"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		AllowAllOrigins:  true,
	}))

	router.POST("/sendTransaction", func(c *gin.Context) {
		var request TransactionRequest
		if err := c.ShouldBindJSON(&request); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if request.Target != globalConfig.TargetContract {
			c.JSON(http.StatusBadRequest, gin.H{"error": "target is not the kashpool address"})
			return
		}

		data, err := common.ParseHexOrString(request.CallData)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		txHash, err := sendTransaction(request.Target, data)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"txHash": txHash, "status": "pending"})
	})

	fmt.Println(globalConfig.RunPort)
	router.Run(globalConfig.RunPort)
}

// config
// ------
var globalConfig Config

type Config struct {
	RPC            string         `yaml:"rpc"`
	PrivateKey     string         `yaml:"private_key"`
	TargetContract common.Address `yaml:"target_contract"`
	ChainID        uint64         `yaml:"chainId"`
	RunPort        string         `yaml:"run_port"`
}

func loadConfig(file string) error {
	data, err := ioutil.ReadFile(file)
	if err != nil {
		return fmt.Errorf("failed to read config file: %v", err)
	}

	var config Config
	err = yaml.Unmarshal(data, &config)
	if err != nil {
		return fmt.Errorf("failed to unmarshal config data: %v", err)
	}

	if config.RPC == "" {
		return fmt.Errorf("missing rpc")
	}
	globalConfig = config
	return nil
}

func sendTransaction(targetAddress common.Address, callData []byte) (string, error) {
	// 连接到以太坊网络
	client, err := ethclient.Dial(globalConfig.RPC)
	if err != nil {
		return "", fmt.Errorf("failed to connect to the Ethereum network: %v", err)
	}

	// TODO: save private key in a secure way
	// 用私钥解锁账户
	privateKey, err := crypto.HexToECDSA(globalConfig.PrivateKey)
	if err != nil {
		return "", fmt.Errorf("failed to unlock account: %v", err)
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		return "", fmt.Errorf("bad public key")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		return "", fmt.Errorf("failed to get account nonce: %v", err)
	}

	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		return "", fmt.Errorf("failed to get gas price: %v", err)
	}

	gasLimit, err := client.EstimateGas(context.Background(), ethereum.CallMsg{
		From: fromAddress,
		To:   &targetAddress,
		Data: callData,
	})
	if err != nil {
		return "", fmt.Errorf("failed to estimate: %v", err)
	}

	// 设置交易参数
	tx := types.NewTransaction(nonce, targetAddress, big.NewInt(0), gasLimit*120/100, gasPrice, callData)

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(big.NewInt(0).SetUint64(globalConfig.ChainID)), privateKey)
	if err != nil {
		return "", fmt.Errorf("failed to sign transaction: %v", err)
	}

	// 发送交易
	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		return "", fmt.Errorf("failed to send transaction: %v", err)
	}

	return signedTx.Hash().Hex(), nil
}
