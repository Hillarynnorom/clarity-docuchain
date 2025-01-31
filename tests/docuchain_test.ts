import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can store a new document",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const documentHash = "0x0000000000000000000000000000000000000000000000000000000000000001";
    
    let block = chain.mineBlock([
      Tx.contractCall("docuchain", "store-document", 
        [types.buff(documentHash), types.utf8("test-doc")], 
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), true);
  },
});

Clarinet.test({
  name: "Cannot store duplicate document",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const documentHash = "0x0000000000000000000000000000000000000000000000000000000000000001";
    
    let block = chain.mineBlock([
      Tx.contractCall("docuchain", "store-document",
        [types.buff(documentHash), types.utf8("test-doc")],
        wallet_1.address
      ),
      Tx.contractCall("docuchain", "store-document",
        [types.buff(documentHash), types.utf8("test-doc-2")],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), true);
    assertEquals(block.receipts[1].result.expectErr(), "u102");
  },
});

Clarinet.test({
  name: "Can transfer document ownership",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const documentHash = "0x0000000000000000000000000000000000000000000000000000000000000001";
    
    let block = chain.mineBlock([
      Tx.contractCall("docuchain", "store-document",
        [types.buff(documentHash), types.utf8("test-doc")],
        wallet_1.address
      ),
      Tx.contractCall("docuchain", "transfer-ownership",
        [types.buff(documentHash), types.principal(wallet_2.address)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[1].result.expectOk(), true);
  },
});
