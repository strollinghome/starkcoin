COMPILER_VERSION = 2.1.0
RPC_URL = http://0.0.0.0:5050
ACCOUNT_DESCRIPTOR = ~/.starknet-wallets/account0_account.json
ACCOUNT_KEY_STORE = ~/.starknet-wallets/account0_keystore.json


declare-erc20:; 
	starkli declare target/dev/starkcoin_ERC20.sierra.json \
	--compiler-version $(COMPILER_VERSION) \
	--rpc $(RPC_URL) \
	--account $(ACCOUNT_DESCRIPTOR) \
	--keystore $(ACCOUNT_KEY_STORE)

declare-factory:; 
	starkli declare target/dev/starkcoin_Factory.sierra.json \
	--compiler-version $(COMPILER_VERSION) \
	--rpc $(RPC_URL) \
	--account $(ACCOUNT_DESCRIPTOR) \
	--keystore $(ACCOUNT_KEY_STORE)

deploy-factory:
	starkli deploy \
	--rpc $(RPC_URL) \
	--account $(ACCOUNT_DESCRIPTOR) \
	--keystore $(ACCOUNT_KEY_STORE) \
	$(CLASS_HASH)