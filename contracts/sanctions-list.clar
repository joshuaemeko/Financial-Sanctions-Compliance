;; Sanctions List Contract
;; Records restricted parties and jurisdictions

(define-data-var admin principal tx-sender)

;; Sanctioned entity record
(define-map sanctioned-entities
  { entity-id: (string-utf8 36) }
  {
    name: (string-utf8 100),
    reason: (string-utf8 200),
    jurisdiction: (string-utf8 50),
    added-at: uint,
    added-by: principal,
    active: bool
  }
)

;; Sanctioned jurisdictions
(define-map sanctioned-jurisdictions
  { code: (string-utf8 10) }
  {
    name: (string-utf8 50),
    reason: (string-utf8 200),
    added-at: uint,
    added-by: principal,
    active: bool
  }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Add a sanctioned entity (admin only)
(define-public (add-sanctioned-entity
  (entity-id (string-utf8 36))
  (name (string-utf8 100))
  (reason (string-utf8 200))
  (jurisdiction (string-utf8 50)))
  (begin
    (asserts! (is-admin) (err u403)) ;; Unauthorized

    (map-set sanctioned-entities
      { entity-id: entity-id }
      {
        name: name,
        reason: reason,
        jurisdiction: jurisdiction,
        added-at: block-height,
        added-by: tx-sender,
        active: true
      }
    )
    (ok true)
  )
)

;; Remove a sanctioned entity (admin only)
(define-public (remove-sanctioned-entity (entity-id (string-utf8 36)))
  (begin
    (asserts! (is-admin) (err u403)) ;; Unauthorized
    (asserts! (is-some (map-get? sanctioned-entities { entity-id: entity-id })) (err u404)) ;; Entity not found

    (map-set sanctioned-entities
      { entity-id: entity-id }
      (merge (unwrap-panic (map-get? sanctioned-entities { entity-id: entity-id }))
        { active: false }
      )
    )
    (ok true)
  )
)

;; Add a sanctioned jurisdiction (admin only)
(define-public (add-sanctioned-jurisdiction
  (code (string-utf8 10))
  (name (string-utf8 50))
  (reason (string-utf8 200)))
  (begin
    (asserts! (is-admin) (err u403)) ;; Unauthorized

    (map-set sanctioned-jurisdictions
      { code: code }
      {
        name: name,
        reason: reason,
        added-at: block-height,
        added-by: tx-sender,
        active: true
      }
    )
    (ok true)
  )
)

;; Remove a sanctioned jurisdiction (admin only)
(define-public (remove-sanctioned-jurisdiction (code (string-utf8 10)))
  (begin
    (asserts! (is-admin) (err u403)) ;; Unauthorized
    (asserts! (is-some (map-get? sanctioned-jurisdictions { code: code })) (err u404)) ;; Jurisdiction not found

    (map-set sanctioned-jurisdictions
      { code: code }
      (merge (unwrap-panic (map-get? sanctioned-jurisdictions { code: code }))
        { active: false }
      )
    )
    (ok true)
  )
)

;; Check if entity is sanctioned
(define-read-only (is-entity-sanctioned (entity-id (string-utf8 36)))
  (match (map-get? sanctioned-entities { entity-id: entity-id })
    entity (ok (get active entity))
    (err u404) ;; Entity not found in sanctions list
  )
)

;; Check if jurisdiction is sanctioned
(define-read-only (is-jurisdiction-sanctioned (code (string-utf8 10)))
  (match (map-get? sanctioned-jurisdictions { code: code })
    jurisdiction (ok (get active jurisdiction))
    (err u404) ;; Jurisdiction not found in sanctions list
  )
)

;; Transfer admin rights (admin only)
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403)) ;; Unauthorized
    (var-set admin new-admin)
    (ok true)
  )
)
