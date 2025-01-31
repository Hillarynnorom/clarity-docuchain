;; DocuChain - Document verification and storage system

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-already-exists (err u102))

;; Data structures
(define-map documents
  { hash: (buff 32) }
  {
    owner: principal,
    name: (string-utf8 256),
    timestamp: uint,
    verified: bool
  })

(define-map document-history
  { hash: (buff 32) }
  { previous-owners: (list 20 principal) })

;; Public functions
(define-public (store-document (document-hash (buff 32)) (name (string-utf8 256)))
  (let ((existing-doc (get-document-info document-hash)))
    (match existing-doc
      success (err err-already-exists)
      error (begin
        (map-set documents
          { hash: document-hash }
          {
            owner: tx-sender,
            name: name,
            timestamp: block-height,
            verified: true
          })
        (ok true)))))

(define-public (verify-document (document-hash (buff 32)))
  (match (get-document-info document-hash)
    success (ok true)
    error (err err-not-found)))

(define-public (transfer-ownership (document-hash (buff 32)) (new-owner principal))
  (let ((doc-info (get-document-info document-hash)))
    (match doc-info
      error (err err-not-found)
      success (if (is-eq tx-sender (get owner success))
        (begin
          (update-history document-hash (get owner success))
          (map-set documents
            { hash: document-hash }
            (merge success { owner: new-owner }))
          (ok true))
        (err err-unauthorized)))))

;; Private functions
(define-private (update-history (document-hash (buff 32)) (previous-owner principal))
  (let ((history (get-history document-hash)))
    (match history
      previous-list (map-set document-history
        { hash: document-hash }
        { previous-owners: (unwrap-panic (as-max-len? (append previous-list previous-owner) u20)) })
      error (map-set document-history
        { hash: document-hash }
        { previous-owners: (list previous-owner) }))))

;; Read only functions  
(define-read-only (get-document-info (document-hash (buff 32)))
  (map-get? documents { hash: document-hash }))

(define-read-only (get-history (document-hash (buff 32)))
  (get previous-owners (default-to
    { previous-owners: (list) }
    (map-get? document-history { hash: document-hash }))))
