import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can store a new document with metadata and expiration",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const documentHash = "0x0000000000000000000000000000000000000000000000000000000000000001";
    const expiryBlock = 100000;
    
    let block = chain.mineBlock([
      Tx.contractCall("docuchain", "store-document", 
        [
          types.buff(documentHash),
          types.utf8("test-doc"),
          types.some(types.utf8("test metadata")),
          types.some(types.uint(expiryBlock))
        ], 
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), true);
  },
});

Clarinet.test({
  name: "Document verification respects expiration",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const documentHash = "0x0000000000000000000000000000000000000000000000000000000000000001";
    const expiryBlock = chain.blockHeight + 10;
    
    let block = chain.mineBlock([
      Tx.contractCall("docuchain", "store-document",
        [
          types.buff(documentHash),
          types.utf8("test-doc"),
          types.none(),
          types.some(types.uint(expiryBlock))
        ],
        wallet_1.address
      )
    ]);
    
    // Verify before expiration
    block = chain.mineBlock([
      Tx.contractCall("docuchain", "verify-document",
        [types.buff(documentHash)],
        wallet_1.address
      )
    ]);
    assertEquals(block.receipts[0].result.expectOk(), true);
    
    // Mine blocks until after expiration
    chain.mineEmptyBlockUntil(expiryBlock + 1);
    
    // Verify after expiration
    block = chain.mineBlock([
      Tx.contractCall("docuchain", "verify-document",
        [types.buff(documentHash)],
        wallet_1.address
      )
    ]);
    assertEquals(block.receipts[0].result.expectErr(), "u104");
  },
});

Clarinet.test({
  name: "Can manage document status",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const documentHash = "0x0000000000000000000000000000000000000000000000000000000000000001";
    
    let block = chain.mineBlock([
      Tx.contractCall("docuchain", "store-document",
        [types.buff(documentHash), types.utf8("test-doc"), types.none(), types.none()],
        wallet_1.address
      ),
      Tx.contractCall("docuchain", "set-document-status",
        [types.buff(documentHash), types.utf8("inactive")],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[1].result.expectOk(), true);
    
    // Verify inactive document
    block = chain.mineBlock([
      Tx.contractCall("docuchain", "verify-document",
        [types.buff(documentHash)],
        wallet_1.address
      )
    ]);
    assertEquals(block.receipts[0].result.expectErr(), "u105");
  },
});
