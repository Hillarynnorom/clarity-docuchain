;; DocuChain - Document verification and storage system

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-name (err u103))
(define-constant err-expired (err u104))
(define-constant err-inactive (err u105))
(define-constant err-invalid-status (err u106))
(define-constant err-invalid-principal (err u107))

;; Valid status values
(define-data-var valid-statuses (list 3 (string-utf8 10)) (list "active" "inactive" "archived"))

;; Data structures 
(define-map documents
  { hash: (buff 32) }
  {
    owner: principal,
    name: (string-utf8 256),
    timestamp: uint,
    verified: bool,
    metadata: (optional (string-utf8 1024)),
    status: (string-utf8 10),
    expires-at: (optional uint),
    version: uint
  })

;; Owner index
(define-map owner-documents
  { owner: principal }
  { document-hashes: (list 50 (buff 32)) })

;; Rest of the contract remains the same, with these key modifications:

;; Modified transfer-ownership function with zero address check
(define-public (transfer-ownership (document-hash (buff 32)) (new-owner principal))
  (let ((doc-info (get-document-info document-hash)))
    (match doc-info
      error (err err-not-found)
      success (if (and
                (is-eq tx-sender (get owner success))
                (not (is-eq new-owner 'SP000000000000000000002Q6VF78)))
        (begin
          (update-history document-hash (get owner success))
          (update-owner-index document-hash (get owner success) new-owner)
          (map-set documents
            { hash: document-hash }
            (merge success { owner: new-owner }))
          (emit-event "ownership-transferred" document-hash)
          (ok true))
        (err err-unauthorized)))))

;; New helper function for owner index
(define-private (update-owner-index (document-hash (buff 32)) (old-owner principal) (new-owner principal))
  (let (
    (old-docs (default-to { document-hashes: (list) } (map-get? owner-documents { owner: old-owner })))
    (new-docs (default-to { document-hashes: (list) } (map-get? owner-documents { owner: new-owner })))
  )
    (map-set owner-documents
      { owner: old-owner }
      { document-hashes: (filter not-eq? (get document-hashes old-docs) document-hash) })
    (map-set owner-documents
      { owner: new-owner }
      { document-hashes: (unwrap-panic (as-max-len? 
        (append (get document-hashes new-docs) document-hash) u50)) })))

;; Modified set-document-status with validation
(define-public (set-document-status (document-hash (buff 32)) (new-status (string-utf8 10)))
  (let ((doc-info (get-document-info document-hash)))
    (match doc-info
      error (err err-not-found)
      success (if (and 
                (is-eq tx-sender (get owner success))
                (is-valid-status new-status))
        (begin
          (map-set documents
            { hash: document-hash }
            (merge success { status: new-status }))
          (emit-event "status-changed" document-hash)
          (ok true))
        (err err-unauthorized)))))

;; New helper for status validation
(define-private (is-valid-status (status (string-utf8 10)))
  (not (is-none (index-of (var-get valid-statuses) status))))
