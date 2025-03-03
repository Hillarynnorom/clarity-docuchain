// [Previous test content remains, adding new tests:]

Clarinet.test({
  name: "Cannot transfer ownership to zero address",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const documentHash = "0x0000000000000000000000000000000000000000000000000000000000000001";
    
    let block = chain.mineBlock([
      Tx.contractCall("docuchain", "store-document", 
        [types.buff(documentHash), types.utf8("test-doc"), types.none(), types.none()],
        wallet_1.address
      ),
      Tx.contractCall("docuchain", "transfer-ownership",
        [types.buff(documentHash), "SP000000000000000000002Q6VF78"],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[1].result.expectErr(), "u107");
  },
});

// [Additional tests for new functionality...]
