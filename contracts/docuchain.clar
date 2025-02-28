;; DocuChain - Document verification and storage system

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-name (err u103))
(define-constant err-expired (err u104))
(define-constant err-inactive (err u105))

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

(define-map document-history
  { hash: (buff 32) }
  { previous-owners: (list 20 principal) })

(define-map document-versions
  { hash: (buff 32), version: uint }
  { 
    metadata: (optional (string-utf8 1024)),
    timestamp: uint
  })

;; Events
(define-data-var last-event-id uint u0)

(define-map events
  { id: uint }
  {
    event-type: (string-utf8 24),
    document-hash: (buff 32),
    principal: principal,
    timestamp: uint
  })

;; Private functions
(define-private (emit-event (event-type (string-utf8 24)) (document-hash (buff 32)))
  (let ((event-id (+ (var-get last-event-id) u1)))
    (var-set last-event-id event-id)
    (map-set events
      { id: event-id }
      {
        event-type: event-type,
        document-hash: document-hash,
        principal: tx-sender,
        timestamp: block-height
      })
    event-id))

;; Public functions
(define-public (store-document (document-hash (buff 32)) (name (string-utf8 256)) (metadata (optional (string-utf8 1024))) (expires-at (optional uint)))
  (let ((existing-doc (get-document-info document-hash)))
    (match existing-doc
      success (err err-already-exists)
      error (if (> (len name) u0)
        (begin
          (map-set documents
            { hash: document-hash }
            {
              owner: tx-sender,
              name: name,
              timestamp: block-height,
              verified: true,
              metadata: metadata,
              status: "active",
              expires-at: expires-at,
              version: u1
            })
          (emit-event "document-stored" document-hash)
          (ok true))
        (err err-invalid-name)))))

(define-public (verify-document (document-hash (buff 32)))
  (let ((doc-info (get-document-info document-hash)))
    (match doc-info
      error (err err-not-found)
      success (if (is-eq (get status success) "active")
        (if (check-expiration success)
          (ok true)
          (err err-expired))
        (err err-inactive)))))

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
          (emit-event "ownership-transferred" document-hash)
          (ok true))
        (err err-unauthorized)))))

(define-public (update-metadata (document-hash (buff 32)) (new-metadata (optional (string-utf8 1024))))
  (let ((doc-info (get-document-info document-hash)))
    (match doc-info
      error (err err-not-found)
      success (if (is-eq tx-sender (get owner success))
        (begin
          (map-set document-versions
            { hash: document-hash, version: (+ (get version success) u1) }
            { metadata: (get metadata success), timestamp: (get timestamp success) })
          (map-set documents
            { hash: document-hash }
            (merge success { 
              metadata: new-metadata,
              version: (+ (get version success) u1)
            }))
          (emit-event "metadata-updated" document-hash)
          (ok true))
        (err err-unauthorized)))))

(define-public (set-document-status (document-hash (buff 32)) (new-status (string-utf8 10)))
  (let ((doc-info (get-document-info document-hash)))
    (match doc-info
      error (err err-not-found)
      success (if (is-eq tx-sender (get owner success))
        (begin
          (map-set documents
            { hash: document-hash }
            (merge success { status: new-status }))
          (emit-event "status-changed" document-hash)
          (ok true))
        (err err-unauthorized)))))

;; Private helper functions
(define-private (check-expiration (doc-info {owner: principal, name: (string-utf8 256), timestamp: uint, verified: bool, metadata: (optional (string-utf8 1024)), status: (string-utf8 10), expires-at: (optional uint), version: uint}))
  (match (get expires-at doc-info)
    some-expiry (< block-height some-expiry)
    none true))

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

(define-read-only (get-document-version (document-hash (buff 32)) (version uint))
  (map-get? document-versions { hash: document-hash, version: version }))
