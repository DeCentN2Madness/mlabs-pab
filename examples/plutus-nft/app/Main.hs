{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TemplateHaskell #-}

module Main (main) where

import BotPlutusInterface qualified
import BotPlutusInterface.Types (
  CLILocation (Local),
  HasDefinitions (..),
  LogLevel (Debug),
  PABConfig (..),
  SomeBuiltin (..),
  endpointsToSchemas,
 )
import Cardano.Api (NetworkId (Testnet), NetworkMagic (..))
import Cardano.PlutusExample.NFT
import Data.Aeson qualified as JSON
import Data.Aeson.TH (defaultOptions, deriveJSON)
import Data.ByteString.Lazy qualified as LazyByteString
import Data.Default (def)
import Data.Maybe (fromMaybe)
import Playground.Types (FunctionSchema)
import Schema (FormSchema)
import Servant.Client.Core (BaseUrl (BaseUrl), Scheme (Http))
import Prelude

instance HasDefinitions MintNFTContracts where
  getDefinitions :: [MintNFTContracts]
  getDefinitions = []

  getSchema :: MintNFTContracts -> [FunctionSchema FormSchema]
  getSchema _ = endpointsToSchemas @NFTSchema

  getContract :: (MintNFTContracts -> SomeBuiltin)
  getContract = \case
    MintNFT p ->
      SomeBuiltin $
        mintNft p

newtype MintNFTContracts = MintNFT MintParams
  deriving stock (Show)

$(deriveJSON defaultOptions ''MintNFTContracts)

{-
{
  "caID": {
    "mpName": "Awesome NFT",
    "mpDescription": "My awesome NFT",
    "mpImage": "ipfs://QmPu9vsCw7UZcUKMLVFcj1WpJQXVFKrJXo5cEBajK6tYQT",
    "mpTokenName": {
      "unTokenName": "NFT"
    },
    "mpPubKeyHash": {
      "unPaymentPubKeyHash": {
        "getPubKeyHash": "49839770109f411eb1308dd99a28bc5b820e6a69d16aecda6282b4c7"
      }
    },
    "mpStakeHash": {
      "unStakePubKeyHash": {
        "getPubKeyHash": "1b53992caf87760501080d490fd12a4723c6e650584899ac28fd6346"
      }
    }
  }
}
-}

main :: IO ()
main = do
  protocolParams <-
    fromMaybe (error "protocol.json file not found") . JSON.decode
      <$> LazyByteString.readFile "protocol.json"
  let pabConf =
        PABConfig
          { pcCliLocation = Local
          , pcNetwork = Testnet (NetworkMagic 1097911063)
          , pcChainIndexUrl = BaseUrl Http "localhost" 9083 ""
          , pcPort = 9080
          , pcProtocolParams = protocolParams
          , pcTipPollingInterval = 10_000_000
          , pcSlotConfig = def
          , pcOwnPubKeyHash = "3f3464650beb5324d0e463ebe81fbe1fd519b6438521e96d0d35bd75"
          , pcScriptFileDir = "./scripts"
          , pcSigningKeyFileDir = "./signing-keys"
          , pcTxFileDir = "./txs"
          , pcDryRun = False
          , pcLogLevel = Debug
          , pcProtocolParamsFile = "./protocol.json"
          , pcEnableTxEndpoint = True
          , pcMetadataDir = "./metadata"
          }
  BotPlutusInterface.runPAB @MintNFTContracts pabConf
