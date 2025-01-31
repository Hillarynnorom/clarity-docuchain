# DocuChain

A decentralized document verification and storage system built on Stacks blockchain.

## Features
- Store document hashes on-chain
- Verify document authenticity
- Manage document ownership and access rights
- Track document history

## Usage

### Store a document
```clarity
(contract-call? .docuchain store-document 0x123... "document-name")
```

### Verify a document
```clarity 
(contract-call? .docuchain verify-document 0x123...)
```

### Transfer ownership
```clarity
(contract-call? .docuchain transfer-ownership 0x123... tx-receiver)
```
