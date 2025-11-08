-include .env

deploy-anvil:
	forge script script/DeployTimelockMultisig.s.sol:DeployTimelockMultisig \
		--rpc-url $(ANVIL_RPC_URL) \
		--broadcast \
		--private-key $(ANVIL_PRIVATE_KEY) \
		-vvvv

test-specific:
	forge test --mt $(TEST) -vvvv
