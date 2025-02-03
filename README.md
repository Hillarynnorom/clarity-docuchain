# DocuChain

A decentralized document verification and storage system built on Stacks blockchain.

## Features
- Store document hashes on-chain with optional metadata
- Verify document authenticity
- Manage document ownership and access rights
- Track document history
- Update document metadata

## Usage

### Store a document
```clarity
(contract-call? .docuchain store-document 0x123... "document-name" (some u"metadata"))
```

### Verify a document
```clarity 
(contract-call? .docuchain verify-document 0x123...)
```

### Transfer ownership
```clarity
(contract-call? .docuchain transfer-ownership 0x123... tx-receiver)
```

### Update metadata
```clarity
(contract-call? .docuchain update-metadata 0x123... (some u"new metadata"))
```

## Input Validation
- Document names cannot be empty
- Metadata is optional and limited to 1024 bytes
- Document hashes must be 32 bytes
