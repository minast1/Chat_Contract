SHELL :=/bin/bash

deploy-anvil:; @forge script script/Chat.s.sol:ChatScript --fork-url http:localhost:8545 --broadcast --interactives 1

build:; forge build

test-anvil:; forge test --rpc-url http:localhost:8545 -vvvv

cleanup:; rm -rf broadcast && rm -rf cache && rm -rf out && forge clean