import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can store a new document with metadata",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const documentHash = "0x0000000000000000000000000000000000000000000000000000000000000001";
    
    let block = chain.mineBlock([
      Tx.contractCall("docuchain", "store-document", 
        [types.buff(documentHash), types.utf8("test-doc"), types.some(types.utf8("test metadata"))], 
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), true);
  },
});

Clarinet.test({
  name: "Cannot store document with empty name",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const documentHash = "0x0000000000000000000000000000000000000000000000000000000000000001";
    
    let block = chain.mineBlock([
      Tx.contractCall("docuchain", "store-document",
        [types.buff(documentHash), types.utf8(""), types.none()],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectErr(), "u103");
  },
});

Clarinet.test({
  name: "Can update document metadata",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const documentHash = "0x0000000000000000000000000000000000000000000000000000000000000001";
    
    let block = chain.mineBlock([
      Tx.contractCall("docuchain", "store-document",
        [types.buff(documentHash), types.utf8("test-doc"), types.none()],
        wallet_1.address
      ),
      Tx.contractCall("docuchain", "update-metadata",
        [types.buff(documentHash), types.some(types.utf8("updated metadata"))],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[1].result.expectOk(), true);
  },
});
