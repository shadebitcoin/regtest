# Regtest environment management Makefile

# Default values
ADDRESS ?= ""
AMOUNT ?= 0
ASSET_AMOUNT ?= 0
ASSET_ID ?= ""
RAW_TX ?= ""
COMMAND ?= ""
INVOICE ?= ""
NODE ?= 1
CHAIN ?= ""
BLOCKS ?= 1
DESCRIPTION ?= ""
LABEL ?= ""
PAYMENT_HASH ?= ""

.PHONY: rpc faucet mint push cln lnd lbtc-faucet mine pay-cln pay-lnd generate invoice-cln invoice-lnd check-invoice

# Generate blocks on specified chain
generate:
	@if [ "$(CHAIN)" = "" ]; then \
		echo "Error: CHAIN is required. Usage: make generate CHAIN=bitcoin|elements [BLOCKS=1]"; \
		exit 1; \
	fi
	@if [ "$(CHAIN)" = "bitcoin" ]; then \
		docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && bitcoin-cli-sim-client -generate $(BLOCKS)"; \
	elif [ "$(CHAIN)" = "elements" ]; then \
		docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && elements-cli-sim-client -generate $(BLOCKS)"; \
	else \
		echo "Error: CHAIN must be either 'bitcoin' or 'elements'"; \
		exit 1; \
	fi

# Mine blocks on both chains
mine:
	docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && bitcoin-cli-sim-client -generate 1 && elements-cli-sim-client -generate 1"

# Bitcoin/Elements RPC commands
rpc:
	@if [ "$(COMMAND)" = "" ]; then \
		echo "Error: COMMAND is required. Usage: make rpc COMMAND='your command'"; \
		exit 1; \
	fi
	@if echo "$(COMMAND)" | grep -q "bitcoin"; then \
		docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && bitcoin-cli-sim-client $(COMMAND)"; \
	elif echo "$(COMMAND)" | grep -q "elements"; then \
		docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && elements-cli-sim-client $(COMMAND)"; \
	else \
		echo "Error: Command must contain 'bitcoin' or 'elements'"; \
		exit 1; \
	fi

# Generate and send Bitcoin to an address
faucet:
	@if [ "$(ADDRESS)" = "" ]; then \
		echo "Error: ADDRESS is required. Usage: make faucet ADDRESS='your address'"; \
		exit 1; \
	fi
	@if [ "$(AMOUNT)" = "0" ]; then \
		echo "Error: AMOUNT is required. Usage: make faucet ADDRESS='your address' AMOUNT=1000000"; \
		exit 1; \
	fi
	docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && bitcoin-cli-sim-client -generate 1 && bitcoin-cli-sim-client sendtoaddress $(ADDRESS) $(AMOUNT)"

# Generate and send L-BTC to an address
lbtc-faucet:
	@if [ "$(ADDRESS)" = "" ]; then \
		echo "Error: ADDRESS is required. Usage: make lbtc-faucet ADDRESS='your address'"; \
		exit 1; \
	fi
	@if [ "$(AMOUNT)" = "0" ]; then \
		echo "Error: AMOUNT is required. Usage: make lbtc-faucet ADDRESS='your address' AMOUNT=1000000"; \
		exit 1; \
	fi
	docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && elements-cli-sim-client -generate 1 && elements-cli-sim-client sendtoaddress $(ADDRESS) $(AMOUNT)"

# Issue and send Liquid assets
mint:
	@if [ "$(ADDRESS)" = "" ]; then \
		echo "Error: ADDRESS is required. Usage: make mint ADDRESS='your address' ASSET_AMOUNT=1000000"; \
		exit 1; \
	fi
	@if [ "$(ASSET_AMOUNT)" = "0" ]; then \
		echo "Error: ASSET_AMOUNT is required. Usage: make mint ADDRESS='your address' ASSET_AMOUNT=1000000"; \
		exit 1; \
	fi
	@if [ "$(ASSET_ID)" = "" ]; then \
		echo "Error: ASSET_ID is required. Usage: make mint ADDRESS='your address' ASSET_AMOUNT=1000000 ASSET_ID='your asset id'"; \
		exit 1; \
	fi
	docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && elements-cli-sim-client -generate 1 && elements-cli-sim-client sendtoaddress $(ADDRESS) $(ASSET_AMOUNT) \"\" \"\" false $(ASSET_ID)"

# Broadcast raw transaction
push:
	@if [ "$(RAW_TX)" = "" ]; then \
		echo "Error: RAW_TX is required. Usage: make push RAW_TX='your raw transaction'"; \
		exit 1; \
	fi
	docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && elements-cli-sim-client sendrawtransaction $(RAW_TX)"

# Core Lightning commands
cln:
	@if [ "$(COMMAND)" = "" ]; then \
		echo "Error: COMMAND is required. Usage: make cln COMMAND='your command'"; \
		exit 1; \
	fi
	docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && lightning-cli-sim $(NODE) $(COMMAND)"

# LND commands
lnd:
	@if [ "$(COMMAND)" = "" ]; then \
		echo "Error: COMMAND is required. Usage: make lnd COMMAND='your command'"; \
		exit 1; \
	fi
	docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && lncli-sim 2 $(COMMAND)"

# Pay invoice with Core Lightning
pay-cln:
	@if [ "$(INVOICE)" = "" ]; then \
		echo "Error: INVOICE is required. Usage: make pay-cln INVOICE='your invoice'"; \
		exit 1; \
	fi
	docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && lightning-cli-sim $(NODE) pay $(INVOICE)"

# Pay invoice with LND
pay-lnd:
	@if [ "$(INVOICE)" = "" ]; then \
		echo "Error: INVOICE is required. Usage: make pay-lnd INVOICE='your invoice'"; \
		exit 1; \
	fi
	docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && lncli-sim 2 payinvoice $(INVOICE)"

# Create invoice with Core Lightning
invoice-cln:
	@if [ "$(AMOUNT)" = "0" ]; then \
		echo "Error: AMOUNT is required. Usage: make invoice-cln AMOUNT=0.001 LABEL='your label' [DESCRIPTION='your description']"; \
		exit 1; \
	fi
	@if [ "$(LABEL)" = "" ]; then \
		echo "Error: LABEL is required. Usage: make invoice-cln AMOUNT=0.001 LABEL='your label' [DESCRIPTION='your description']"; \
		exit 1; \
	fi
	docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && lightning-cli-sim $(NODE) invoice $(shell echo '$(AMOUNT) * 1000' | bc) '$(LABEL)' '$(DESCRIPTION)' 3600"

# Create invoice with LND
invoice-lnd:
	@if [ "$(AMOUNT)" = "0" ]; then \
		echo "Error: AMOUNT is required. Usage: make invoice-lnd AMOUNT=0.001 LABEL='your label' [DESCRIPTION='your description']"; \
		exit 1; \
	fi
	@if [ "$(LABEL)" = "" ]; then \
		echo "Error: LABEL is required. Usage: make invoice-lnd AMOUNT=0.001 LABEL='your label' [DESCRIPTION='your description']"; \
		exit 1; \
	fi
	docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && lncli-sim 2 addinvoice --amt $(shell echo '$(AMOUNT) * 100000000' | bc) --label '$(LABEL)' --memo '$(DESCRIPTION)'"

# Check invoice status
check-invoice:
	@if [ "$(PAYMENT_HASH)" = "" ]; then \
		echo "Error: PAYMENT_HASH is required. Usage: make check-invoice PAYMENT_HASH='your payment hash'"; \
		exit 1; \
	fi
	docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && lightning-cli-sim $(NODE) listinvoices payment_hash=$(PAYMENT_HASH)"

# Help target
help:
	@echo "Available targets:"
	@echo "  rpc         - Invoke bitcoin-cli or elements-cli (COMMAND required)"
	@echo "  faucet      - Generate and send bitcoin to address (ADDRESS and AMOUNT required)"
	@echo "  lbtc-faucet - Generate and send L-BTC to address (ADDRESS and AMOUNT required)"
	@echo "  mint        - Issue and send Liquid assets (ADDRESS, ASSET_AMOUNT, and ASSET_ID required)"
	@echo "  push        - Broadcast raw transaction (RAW_TX required)"
	@echo "  cln         - Invoke Core Lightning command (COMMAND required, NODE=1|2)"
	@echo "  lnd         - Invoke LND command (COMMAND required)"
	@echo "  mine        - Mine blocks on both Bitcoin and Elements chains"
	@echo "  generate    - Generate blocks on specified chain (CHAIN=bitcoin|elements required, BLOCKS=1)"
	@echo "  pay-cln     - Pay invoice using Core Lightning (INVOICE required, NODE=1|2)"
	@echo "  pay-lnd     - Pay invoice using LND (INVOICE required)"
	@echo "  invoice-cln - Create invoice with Core Lightning (AMOUNT and LABEL required, NODE=1|2, optional DESCRIPTION)"
	@echo "  invoice-lnd - Create invoice with LND (AMOUNT and LABEL required, optional DESCRIPTION)"
	@echo "  check-invoice - Check invoice status by payment hash (PAYMENT_HASH required, NODE=1|2)"
	@echo ""
	@echo "Examples:"
	@echo "  make rpc COMMAND='bitcoin getblockcount'"
	@echo "  make faucet ADDRESS='bcrt1...' AMOUNT=1000000"
	@echo "  make lbtc-faucet ADDRESS='el1...' AMOUNT=1000000"
	@echo "  make mint ADDRESS='el1...' ASSET_AMOUNT=1000000 ASSET_ID='asset_id'"
	@echo "  make push RAW_TX='02000000...'"
	@echo "  make cln COMMAND='listinvoices' NODE=1"
	@echo "  make lnd COMMAND='listchannels'"
	@echo "  make mine"
	@echo "  make generate CHAIN=bitcoin BLOCKS=10"
	@echo "  make pay-cln INVOICE='lnbc1...' NODE=1"
	@echo "  make pay-lnd INVOICE='lnbc1...'"
	@echo "  make invoice-cln AMOUNT=0.001 LABEL='test-invoice' DESCRIPTION='Test invoice' NODE=1"
	@echo "  make invoice-lnd AMOUNT=0.001 LABEL='test-invoice' DESCRIPTION='Test invoice'"
	@echo "  make check-invoice PAYMENT_HASH='payment_hash' NODE=1" 